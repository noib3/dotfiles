# Brave custom search engines submodule.
#
# Manages keyword-triggered search engines by writing directly to Brave's
# "Web Data" SQLite database via a home.activation script.
#
# Exposes a read-only `_sqlScript` derivation that the parent module wires
# into the activation script.

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
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
  }) config.engines;

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
in
{
  options = {
    engines = mkOption {
      type = types.attrsOf engineType;
      default = { };
      description = ''
        Custom search engines. The attribute name is used as the keyword
        (shortcut) for the engine.
      '';
    };

    _sqlScript = mkOption {
      type = types.package;
      readOnly = true;
      internal = true;
      description = "Derivation containing the SQL script to apply.";
    };
  };

  config = {
    _sqlScript = pkgs.writeText "brave-search-engines.sql" sqlScript;
  };
}
