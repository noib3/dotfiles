{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.fonts;
  fontSubmodule = import ./font-submodule.nix { inherit lib; };
in
{
  imports = [
    ./emoji
    ./monospace
    ./sans-serif
    ./serif
    ./stacks
  ];

  options.modules.fonts = {
    monospace = mkOption {
      type = types.attrsOf fontSubmodule;
      default = { };
      description = "All declared monospace fonts";
    };

    sansSerif = mkOption {
      type = types.attrsOf fontSubmodule;
      default = { };
      description = "All declared sans-serif fonts";
    };

    serif = mkOption {
      type = types.attrsOf fontSubmodule;
      default = { };
      description = "All declared serif fonts";
    };

    emoji = mkOption {
      type = types.attrsOf fontSubmodule;
      default = { };
      description = "All declared emoji fonts";
    };
  };

  config =
    let
      current = cfg.stacks.current;
    in
    {
      home.packages = unique [
        current.monospace.package
        current.sansSerif.package
        current.serif.package
        current.emoji.package
      ];

      fonts.fontconfig = {
        enable = pkgs.stdenv.isLinux;
        defaultFonts = {
          serif = [ current.serif.name ];
          sansSerif = [ current.sansSerif.name ];
          monospace = [ current.monospace.name ];
          emoji = [ current.emoji.name ];
        };
      };
    };
}
