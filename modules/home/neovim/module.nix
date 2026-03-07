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
      };
    };

    includeConfig = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to bundle the Neovim configuration into the package's runtime
        path. Set to false when providing the configuration externally (e.g. via
        a symlink to ~/.config/nvim).
      '';
    };

    palette = mkOption {
      type = types.attrs;
      default = import ./palettes/gruvbox.nix;
      description = "The colorscheme palette to generate into Lua";
    };
  };
}
