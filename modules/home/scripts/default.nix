{
  config,
  lib,
  pkgs,
  colorscheme,
  ...
}:

with lib;
let
  cfg = config.scripts;
in
{
  options.scripts = {
    palette = mkOption {
      type = types.str;
      default = colorscheme;
      description = "The palette to use.";
    };

    fuzzy-ripgrep = mkOption {
      type = types.package;
      default = import ./fuzzy-ripgrep.nix { inherit pkgs; };
    };

    lf-recursive = mkOption {
      type = types.package;
      default =
        let
          palette = import (../../../palettes + "/${cfg.palette}.nix");
        in
        import ./lf-recursive.nix { inherit config pkgs palette; };
    };

    preview = mkOption {
      type = types.package;
      default = import ./preview.nix { inherit pkgs; };
    };

    rg-pattern = mkOption {
      type = types.package;
      default = import ./rg-pattern.nix { inherit pkgs; };
    };

    rg-preview = mkOption {
      type = types.package;
      default = import ./rg-preview.nix { inherit pkgs; };
    };
  };
}
