# Shared type definitions for the font module system.
{ lib }:

with lib;
let
  fontSubmodule = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        example = "IosevkaTerm Nerd Font";
        description = "The font family name as known to fontconfig";
      };

      package = mkOption {
        type = types.package;
        example = "pkgs.nerd-fonts.iosevka-term";
        description = "The Nix package providing the font";
      };

      styles = {
        normal = mkOption {
          type = types.str;
          default = "Regular";
          description = "The normal font style";
        };

        bold = mkOption {
          type = types.str;
          default = "Bold";
          description = "The bold font style";
        };

        italic = mkOption {
          type = types.str;
          default = "Italic";
          description = "The italic font style";
        };

        boldItalic = mkOption {
          type = types.str;
          default = "Bold Italic";
          description = "The bold italic font style";
        };
      };

      sizes = mkOption {
        type = types.attrsOf types.float;
        example = {
          default = 16.5;
          ghostty = 14.0;
        };
        description = ''
          Font sizes keyed by program name, with a mandatory `default` entry.
          Accessed as a functor: `font.sizes "ghostty"` returns the
          ghostty-specific size if defined, otherwise the default.
        '';
      };
    };
  };

  # A sizes attrset that uses __functor to fall back to `default` for any
  # program that doesn't have an explicit override.
  mkSizesFunctor =
    sizesAttr:
    let
      overrides = removeAttrs sizesAttr [ "default" ];
    in
    {
      inherit (sizesAttr) default;
      __functor = self: program: overrides.${program} or self.default;
    }
    // overrides;

  wrapFont =
    fontDef:
    fontDef
    // {
      sizes = mkSizesFunctor fontDef.sizes;
    };
in
{
  inherit fontSubmodule mkSizesFunctor wrapFont;
}
