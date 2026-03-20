# Per-profile Brave configuration module.
#
# Each profile (e.g. "Default", "Profile 1") has:
#
#   - preferences: a nested attrset that gets flattened into [{path, value}]
#     pairs and applied to the profile's Preferences JSON file via jq.
#
#   - searchEngines: keyword-triggered search engines written to the
#     profile's Web Data SQLite database.
#
# Pinned extension IDs (from modules.brave.extensions) are automatically
# merged into each profile's preferences under extensions.pinned_extensions.

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.brave;
  inherit (pkgs.stdenv) isDarwin;

  braveDataDir = "${config.home.homeDirectory}/Library/Application Support/BraveSoftware/Brave-Browser";

  # ── Extension pinning ──────────────────────────────────────────────────

  pinnedExtensionIds = mapAttrsToList (_: ext: ext.id) (
    filterAttrs (_: ext: ext.pinned) cfg.extensions
  );

  # ── Preferences ────────────────────────────────────────────────────────

  # Flatten a nested attrset into a list of [{path, value}] pairs suitable
  # for jq's setpath().
  flattenPrefs =
    prefix: attrs:
    concatLists (
      mapAttrsToList (
        k: v:
        let
          path = prefix ++ [ k ];
        in
        if isAttrs v && !(isList v) then
          flattenPrefs path v
        else
          [
            {
              inherit path;
              value = v;
            }
          ]
      ) attrs
    );

  mkPrefUpdates =
    profileName: profileCfg:
    let
      merged =
        profileCfg.preferences
        // optionalAttrs (pinnedExtensionIds != [ ]) {
          extensions.pinned_extensions = pinnedExtensionIds;
        };
    in
    builtins.toJSON (flattenPrefs [ ] merged);

  mkPreferencesActivation =
    profileName: profileCfg:
    let
      prefUpdates = mkPrefUpdates profileName profileCfg;
      preferencesPath = "${braveDataDir}/${profileName}/Preferences";
      hashName = "brave-preferences-${lib.strings.sanitizeDerivationName profileName}";
    in
    nameValuePair "setBravePreferences-${profileName}" (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        is_brave_running() {
          /usr/bin/pgrep -x "Brave Browser" > /dev/null 2>&1
        }

        apply_brave_preferences() {
          # Exit early if Preferences doesn't exist yet.
          [[ -f "${preferencesPath}" ]] || return 0

          # Generate the checksum of the preference updates.
          pref_hash=$(echo -n '${prefUpdates}' | ${pkgs.openssl}/bin/openssl dgst -sha256 | cut -d' ' -f2)
          hash_file="${config.xdg.cacheHome}/home-manager/${hashName}.hash"

          # Exit early if the preferences haven't changed.
          if [[ -f "$hash_file" ]] && [[ "$(cat "$hash_file")" == "$pref_hash" ]]; then
            echo "Brave preferences (${profileName}) already up to date"
            return 0
          fi

          # Brave writes the Preferences file on exit, so we need to quit
          # it first.
          brave_was_running=0
          if is_brave_running; then
            brave_was_running=1
            run /usr/bin/osascript -e 'quit app "Brave Browser"'
            while is_brave_running; do /bin/sleep 0.5; done
          fi

          # Apply each preference update.
          run ${pkgs.jq}/bin/jq \
            --argjson updates '${prefUpdates}' \
            'reduce $updates[] as $update (.; setpath($update.path; $update.value))' \
            "${preferencesPath}" > "${preferencesPath}.tmp"

          run mv "${preferencesPath}.tmp" "${preferencesPath}"

          # Restart Brave if it was running.
          if [[ "$brave_was_running" -eq 1 ]]; then
            run /usr/bin/open -a "Brave Browser"
          fi

          # Store the hash.
          run mkdir -p "$(dirname "$hash_file")"
          run echo "$pref_hash" > "$hash_file"
        }

        apply_brave_preferences
      ''
    );

  # ── Search engines ─────────────────────────────────────────────────────

  searchEngineType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Display name of the search engine.";
      };
      url = mkOption {
        type = types.str;
        description = "Search URL template. Use {searchTerms} as placeholder.";
      };
      favicon_url = mkOption {
        type = types.str;
        default = "";
        description = "URL to the search engine's favicon.";
      };
    };
  };

  nix2Sql =
    v: if builtins.isString v then "'${builtins.replaceStrings [ "'" ] [ "''" ] v}'" else toString v;

  mkSqlScript =
    profileCfg:
    let
      enginesList = mapAttrsToList (keyword: engine: {
        inherit keyword;
        short_name = engine.name;
        inherit (engine) url favicon_url;
        safe_for_autoreplace = 0;
        created_by_policy = 1;
        input_encodings = "UTF-8";
      }) profileCfg.searchEngines;
    in
    pkgs.writeText "brave-search-engines.sql" ''
      -- Remove all policy-managed search engines.
      DELETE FROM keywords WHERE created_by_policy = 1;

      -- Insert the configured search engines.
      ${concatMapStringsSep "\n" (
        engine:
        let
          columns = builtins.attrNames engine;
          values = map (col: nix2Sql engine.${col}) columns;
        in
        "INSERT INTO keywords (${concatStringsSep ", " columns}) VALUES (${concatStringsSep ", " values});"
      ) enginesList}
    '';

  mkSearchEnginesActivation =
    profileName: profileCfg:
    let
      sqlScriptFile = mkSqlScript profileCfg;
      dbPath = "${braveDataDir}/${profileName}/Web Data";
      hashName = "brave-search-engines-${lib.strings.sanitizeDerivationName profileName}";
    in
    nameValuePair "setBraveSearchEngines-${profileName}" (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        is_brave_running() {
          /usr/bin/pgrep -x "Brave Browser" > /dev/null 2>&1
        }

        apply_brave_search_engines() {
          # Exit early if Brave hasn't yet created the DB.
          [[ -f "${dbPath}" ]] || return 0

          # Generate the checksum of the SQL script.
          script_hash=$(${pkgs.openssl}/bin/openssl dgst -sha256 ${sqlScriptFile} | cut -d' ' -f2)
          hash_file="${config.xdg.cacheHome}/home-manager/${hashName}.hash"

          # Exit early if the search engines haven't changed.
          if [[ -f "$hash_file" ]] && [[ "$(cat "$hash_file")" == "$script_hash" ]]; then
            echo "Brave search engines (${profileName}) already up to date"
            return 0
          fi

          # The database is locked while Brave is running, so we need to
          # quit it first.
          brave_was_running=0
          if is_brave_running; then
            brave_was_running=1
            run /usr/bin/osascript -e 'quit app "Brave Browser"'
            while is_brave_running; do /bin/sleep 0.5; done
          fi

          # Apply SQL changes.
          run ${pkgs.sqlite}/bin/sqlite3 "${dbPath}" < ${sqlScriptFile}

          # Restart Brave if it was running.
          if [[ "$brave_was_running" -eq 1 ]]; then
            run /usr/bin/open -a "Brave Browser"
          fi

          # Store the hash.
          run mkdir -p "$(dirname "$hash_file")"
          run echo "$script_hash" > "$hash_file"
        }

        apply_brave_search_engines
      ''
    );

  # ── Profile type ───────────────────────────────────────────────────────

  profileType = types.submodule {
    options = {
      preferences = mkOption {
        type = types.attrs;
        default = { };
        description = ''
          Nested attrset of Brave JSON preferences for this profile.
          Keys mirror the structure of the Preferences JSON file (e.g.
          `brave.new_tab_page.show_stats = false`). Pinned extension IDs
          are merged automatically.
        '';
      };
      searchEngines = mkOption {
        type = types.attrsOf searchEngineType;
        default = { };
        description = ''
          Custom search engines for this profile. The attribute name is
          used as the keyword (shortcut).
        '';
      };
    };
  };

  profilesWithPrefs = filterAttrs (
    _: p: p.preferences != { } || pinnedExtensionIds != [ ]
  ) cfg.profiles;
  profilesWithEngines = filterAttrs (_: p: p.searchEngines != { }) cfg.profiles;
in
{
  options.modules.brave.profiles = mkOption {
    type = types.attrsOf profileType;
    default = { };
    description = ''
      Per-profile Brave configuration. Keys are profile directory names
      (e.g. "Default", "Profile 1").
    '';
  };

  config = mkIf cfg.enable {
    home.activation = mkIf isDarwin (
      (mapAttrs' mkPreferencesActivation profilesWithPrefs)
      // (mapAttrs' mkSearchEnginesActivation profilesWithEngines)
    );
  };
}
