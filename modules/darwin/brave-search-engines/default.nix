{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.brave-search-engines;
  nix2Sql = v: if isString v then "'${builtins.replaceStrings [ "'" ] [ "''" ] v}'" else toString v;
in
{
  options.modules.brave-search-engines = {
    enable = mkEnableOption "Brave search engines";
  };

  config = mkIf cfg.enable (
    let
      searchEngines = {
        nixp = {
          short_name = "Nix packages";
          url = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";
          favicon_url = "https://nixos.org/favicon.ico";
        };
        nixo = {
          short_name = "NixOS options";
          url = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";
          favicon_url = "https://nixos.org/favicon.ico";
        };
        std = {
          short_name = "std's docs";
          url = "https://doc.rust-lang.org/nightly/std/?search={searchTerms}";
          favicon_url = "https://rust-lang.org/logos/rust-logo-blk.svg";
        };
      };
    in
    {
      system.activationScripts.extraActivation.text =
        let
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

          sqlScript = ''
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

          username = config.system.primaryUser;

          dbPath = "/Users/${username}/Library/Application Support/BraveSoftware/Brave-Browser/Default/Web Data";
        in
        ''
          is_brave_running() {
            sudo -u "${username}" pgrep -x "Brave Browser" > /dev/null 2>&1
          }

          # Exit early if Brave hasn't yet created the DB.
          [[ -f "${dbPath}" ]] || exit 0

          # Check if Brave is running.
          brave_was_running=0
          if is_brave_running; then
            brave_was_running=1
            sudo -u "${username}" osascript -e 'quit app "Brave Browser"'
            while is_brave_running; do sleep 0.5; done
          fi

          # Apply SQL changes.
          ${pkgs.sqlite}/bin/sqlite3 "${dbPath}" < ${sqlScriptFile}

          # Restart Brave if it was running.
          if [[ "$brave_was_running" -eq 1 ]]; then
            sudo -u "${username}" -i open -a "Brave Browser" &
          fi
        '';
    }
  );
}
