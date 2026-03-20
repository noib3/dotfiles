{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.fonts;

  fontModule = import ./font-module.nix { inherit lib; };
  inherit (fontModule) fontSubmodule;

  # The set of font categories, mapping directory names to option keys.
  categories = {
    monospace = "monospace";
    sans-serif = "sansSerif";
    serif = "serif";
    emoji = "emoji";
  };

  # Auto-discover .nix files in a directory (excluding default.nix).
  discoverNames =
    dir:
    builtins.readDir dir
    |> attrNames
    |> filter (n: hasSuffix ".nix" n && n != "default.nix" && n != "font-module.nix")
    |> map (removeSuffix ".nix");
in
{
  imports =
    let
      fontImports =
        categories
        |> mapAttrsToList (
          dirName: _:
          let
            dir = ./${dirName};
          in
          discoverNames dir |> map (n: dir + "/${n}.nix")
        )
        |> concatLists;
    in
    [ ./stacks ] ++ fontImports;

  options.modules.fonts = {
    # Per-category attrsets of all declared fonts. Individual font modules
    # append to these via `config.modules.fonts.<category>.<font-name>`.
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
