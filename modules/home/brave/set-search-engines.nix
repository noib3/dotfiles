{
  config,
  pkgs,
  lib,
}:

let
  searchEngines = {
    hm = {
      short_name = "Home Manager Options";
      url = "https://home-manager-options.extranix.com/?query={searchTerms}";
      favicon_url = "https://nixos.org/favicon.ico";
    };
    nixo = {
      short_name = "NixOS options";
      url = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";
      favicon_url = "https://nixos.org/favicon.ico";
    };
    nixp = {
      short_name = "Nix packages";
      url = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";
      favicon_url = "https://nixos.org/favicon.ico";
    };
    std = {
      short_name = "std's docs";
      url = "https://doc.rust-lang.org/nightly/std/?search={searchTerms}";
      favicon_url = "https://rust-lang.org/logos/rust-logo-blk.svg";
    };
  };

  searchEnginesList = lib.mapAttrsToList (
    keyword: attrs:
    attrs
    // {
      inherit keyword;
      safe_for_autoreplace = 0;
      created_by_policy = 1;
      input_encodings = "UTF-8";
    }
  ) searchEngines;

  sqlScript =
    let
      nix2Sql =
        v: if builtins.isString v then "'${builtins.replaceStrings [ "'" ] [ "''" ] v}'" else toString v;
    in
    ''
      -- Remove all policy-managed search engines.
      DELETE FROM keywords WHERE created_by_policy = 1;

      -- Insert the configured search engines.
      ${lib.concatMapStringsSep "\n" (
        engine:
        let
          columns = builtins.attrNames engine;
          values = map (column: nix2Sql engine.${column}) columns;
          columnsStr = lib.concatStringsSep ", " columns;
          valuesStr = lib.concatStringsSep ", " values;
        in
        "INSERT INTO keywords (${columnsStr}) VALUES (${valuesStr});"
      ) searchEnginesList}
    '';

  sqlScriptFile = pkgs.writeText "brave-search-engines.sql" sqlScript;

  dbPath = "${config.home.homeDirectory}/Library/Application Support/BraveSoftware/Brave-Browser/Default/Web Data";
in
''
  is_brave_running() {
    /usr/bin/pgrep -x "Brave Browser" > /dev/null 2>&1
  }

  # Exit early if Brave hasn't yet created the DB.
  [[ -f "${dbPath}" ]] || exit 0

  # Generate the checksum of the SQL script.
  script_hash=$(${pkgs.openssl}/bin/openssl dgst -sha256 ${sqlScriptFile} | cut -d' ' -f2)
  hash_file="${config.xdg.cacheHome}/home-manager/brave-search-engines.hash"

  # Exit early if the search engines haven't changed.
  if [[ -f "$hash_file" ]] && [[ "$(cat "$hash_file")" == "$script_hash" ]]; then
    echo "Brave search engines already up to date"
    exit 0
  fi

  # The database is locked while Brave is running, so we need to quit it first.
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
''
