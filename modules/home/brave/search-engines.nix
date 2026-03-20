# Brave custom search engines module.
#
# Manages keyword-triggered search engines by writing directly to Brave's
# "Web Data" SQLite database via a home.activation script.

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

  engineType = types.submodule {
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

  enginesList = mapAttrsToList (keyword: engine: {
    inherit keyword;
    short_name = engine.name;
    inherit (engine) url favicon_url;
    safe_for_autoreplace = 0;
    created_by_policy = 1;
    input_encodings = "UTF-8";
  }) cfg.searchEngines;

  nix2Sql =
    v: if builtins.isString v then "'${builtins.replaceStrings [ "'" ] [ "''" ] v}'" else toString v;

  sqlScript = ''
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

  sqlScriptFile = pkgs.writeText "brave-search-engines.sql" sqlScript;

  profile = "Default";

  dbPath = "${config.home.homeDirectory}/Library/Application Support/BraveSoftware/Brave-Browser/${profile}/Web Data";
in
{
  options.modules.brave.searchEngines = mkOption {
    type = types.attrsOf engineType;
    default = { };
    description = ''
      Custom search engines. The attribute name is used as the keyword
      (shortcut) for the engine.
    '';
  };

  config = mkIf cfg.enable {
    home.activation = mkIf isDarwin {
      setBraveSearchEngines = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        is_brave_running() {
          /usr/bin/pgrep -x "Brave Browser" > /dev/null 2>&1
        }

        apply_brave_search_engines() {
          # Exit early if Brave hasn't yet created the DB.
          [[ -f "${dbPath}" ]] || return 0

          # Generate the checksum of the SQL script.
          script_hash=$(${pkgs.openssl}/bin/openssl dgst -sha256 ${sqlScriptFile} | cut -d' ' -f2)
          hash_file="${config.xdg.cacheHome}/home-manager/brave-search-engines.hash"

          # Exit early if the search engines haven't changed.
          if [[ -f "$hash_file" ]] && [[ "$(cat "$hash_file")" == "$script_hash" ]]; then
            echo "Brave search engines already up to date"
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
      '';
    };
  };
}
