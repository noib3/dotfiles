{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
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
      nix2Sql = v: if isString v then "'${builtins.replaceStrings [ "'" ] [ "''" ] v}'" else toString v;
    in
    ''
      -- Remove all policy-managed search engines.
      DELETE FROM keywords WHERE created_by_policy = 1;

      -- Insert the configured search engines.
      ${concatMapStringsSep "\n" (
        engine:
        let
          columns = builtins.attrNames engine;
          values = map (column: nix2Sql engine.${column}) columns;
          columnsStr = concatStringsSep ", " columns;
          valuesStr = concatStringsSep ", " values;
        in
        "INSERT INTO keywords (${columnsStr}) VALUES (${valuesStr});"
      ) searchEnginesList}
    '';

  sqlScriptFile = pkgs.writeText "brave-search-engines.sql" sqlScript;

  dbPath = "${config.home.homeDirectory}/Library/Application Support/BraveSoftware/Brave-Browser/Default/Web Data";
in
lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  is_brave_running() {
    /usr/bin/pgrep -x "Brave Browser" > /dev/null 2>&1
  }

  # Exit early if Brave hasn't yet created the DB.
  [[ -f "${dbPath}" ]] || exit 0

  # Check if Brave is running.
  brave_was_running=0
  if is_brave_running; then
    brave_was_running=1
    $DRY_RUN_CMD /usr/bin/osascript -e 'quit app "Brave Browser"'
    while is_brave_running; do /bin/sleep 0.5; done
  fi

  # Apply SQL changes.
  $DRY_RUN_CMD ${pkgs.sqlite}/bin/sqlite3 "${dbPath}" < ${sqlScriptFile}

  # Restart Brave if it was running.
  if [[ "$brave_was_running" -eq 1 ]]; then
    $DRY_RUN_CMD /usr/bin/open -a "Brave Browser" &
  fi
''
