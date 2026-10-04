{
  lib,
  callPackage,
  jq,
  jansson,
  leveldb,
  pkg-config,
  runCommand,
  runCommandCC,
  writeText,
  # ──
  scriptlets,
  profiles,
  dataDir,
  hashFile,
  isDarwin,
}:

let
  installScriptlets =
    runCommandCC "brave-set-scriptlets"
      {
        nativeBuildInputs = [ pkg-config ];
        buildInputs = [
          jansson
          leveldb
        ];
      }
      ''
        $CC -std=c11 -Wall -Wextra -Werror \
          ${./set-scriptlets.c} -o "$out" \
          $(pkg-config --cflags --libs jansson) -lleveldb
      '';
  entries = lib.mapAttrsToList (name: scriptlet: {
    name = "user-nix-${name}.js";
    kind.mime = "application/javascript";
    content = builtins.readFile scriptlet.script;
  }) scriptlets;
  rawResources = writeText "brave-scriptlets-raw.json" (builtins.toJSON entries);
  resources = runCommand "brave-scriptlets.json" { } ''
    ${lib.getExe jq} 'map(.content |= @base64)' ${rawResources} > "$out"
  '';
  rules = writeText "brave-scriptlet-filters.txt" (
    lib.optionalString (scriptlets != { }) ''
      ! BEGIN home-manager Brave scriptlets
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: scriptlet:
          "${lib.concatStringsSep "," scriptlet.domains}##+js(user-nix-${name}.js)"
        ) scriptlets
      )}
      ! END home-manager Brave scriptlets
    ''
  );
in
callPackage ./set-preferences.nix {
  preferencesPath = "${dataDir}/Local State";
  prefUpdates = "[]";
  inherit hashFile isDarwin;
  extraCommands = ''
    ${lib.concatMapStringsSep "\n" (profile: ''
      if [[ -f ${lib.escapeShellArg "${dataDir}/${profile}/Preferences"} ]]; then
        run ${installScriptlets} \
          ${lib.escapeShellArg "${dataDir}/${profile}/AdBlock Custom Resources"} \
          ${resources}
      fi
    '') profiles}
    run ${lib.getExe jq} --rawfile rules ${rules} '
      .brave.ad_block.custom_filters = (
        (.brave.ad_block.custom_filters // "" |
          gsub("(?ms)^! BEGIN home-manager Brave scriptlets\\n.*?^! END home-manager Brave scriptlets\\n?"; ""))
        + $rules
      )
    ' ${lib.escapeShellArg "${dataDir}/Local State"} > ${lib.escapeShellArg "${dataDir}/Local State.tmp"}
    run mv ${lib.escapeShellArg "${dataDir}/Local State.tmp"} ${lib.escapeShellArg "${dataDir}/Local State"}
  '';
}
