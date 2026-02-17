{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.modules.neovim;

  parserLanguage =
    parser:
    if parser ? grammarName then
      parser.grammarName
    else
      throw "Expected parser package with `grammarName` attribute";

  queryLanguage =
    query:
    if query ? language then
      query.language
    else if query ? passthru && query.passthru ? language then
      query.passthru.language
    else
      throw "Expected query package with `language` attribute";

  treesitterParsers =
    cfg.tree-sitter-parsers
    |> map (
      parser:
      let
        lang = parserLanguage parser;
      in
      nameValuePair "nvim/site/parser/${lang}.so" {
        source = "${parser}/parser/${lang}.so";
      }
    )
    |> builtins.listToAttrs;

  treesitterQueries =
    cfg.tree-sitter-queries
    |> map (
      query:
      let
        lang = queryLanguage query;
      in
      nameValuePair "nvim/site/queries/${lang}" {
        source = "${query}/queries/${lang}";
        recursive = true;
      }
    )
    |> builtins.listToAttrs;

  # Converts a Nix value to a Lua value.
  toLua =
    value:
    if builtins.isAttrs value then
      value
      |> lib.mapAttrsToList (k: v: "${k} = ${toLua v}")
      |> builtins.concatStringsSep ", "
      |> (str: "{ ${str} }")
    else if builtins.isString value then
      "'${value}'"
    else
      toString value;
in
{
  options.modules.neovim = {
    enable = mkEnableOption "Neovim";

    tree-sitter-parsers = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Tree-sitter parser packages to install";
    };

    tree-sitter-queries = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Tree-sitter query packages to install";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      inputs.neovim-nightly.packages.${pkgs.stdenv.system}.default
    ];

    home.sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim +Man! -";
    };

    modules.nixpkgs.allowUnfreePackages = [
      "copilot-language-server"
    ];

    modules.neovim.tree-sitter-parsers =
      with pkgs.vimPlugins.nvim-treesitter-parsers; [
        c
        cpp
        lua
        markdown
        markdown_inline
        toml
        vimdoc
      ];

    modules.neovim.tree-sitter-queries =
      with pkgs.vimPlugins.nvim-treesitter.queries; [
        c
        cpp
        lua
        markdown
        markdown_inline
        toml
        vimdoc
      ];

    xdg.configFile.nvim = {
      source = config.lib.file.mkOutOfStoreSymlink (config.lib.mine.mkAbsolute ./.);
    };

    xdg.dataFile = {
      "nvim/site/lua/generated/palette.lua".text =
        "return ${toLua config.modules.colorscheme.palette}";

      "nvim/site/lua/generated/tools.lua".text = ''
        return {
          copilot = "${lib.getExe pkgs.copilot-language-server}";
        }
      '';
    }
    // treesitterParsers
    // treesitterQueries;
  };
}
