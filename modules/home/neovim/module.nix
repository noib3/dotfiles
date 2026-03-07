inputs:

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.neovim;
in
{
  options.neovim = {
    package = mkOption {
      type = types.package;
      description = "The fully configured Neovim package";
      readOnly = true;
      default = pkgs.callPackage ./package {
        inherit inputs;
        inherit (cfg) palette includeConfig;
        extraTreesitterParsers = cfg.tree-sitter-parsers;
        extraTreesitterQueries = cfg.tree-sitter-queries;
      };
    };

    includeConfig = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to bundle the Neovim configuration into the package's
        runtime path. Set to false when providing the configuration
        externally (e.g. via a symlink to ~/.config/nvim).
      '';
    };

    palette = mkOption {
      type = types.attrs;
      default = import ./palettes/gruvbox.nix;
      description = "The colorscheme palette to generate into Lua";
    };

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
}
