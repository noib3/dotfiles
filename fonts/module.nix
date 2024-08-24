{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.fonts;

  mkFontFamily =
    { description }:
    mkOption {
      type = types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            example = "Iosevka Nerd Font";
            description = "The name of the font family";
          };

          package = mkOption {
            type = types.package;
            example = pkgs.fira-sans;
            description = "The package providing the font family";
          };

          size = mkOption {
            type = types.functionTo (types.functionTo types.float);
            example = config: program: if program == "qutebrowser" then 18 else 16;
            description = ''
              The size of the font in a program given the global config and its
              name
            '';
          };

          normal = mkOption {
            type = types.str;
            example = "Regular";
            default = "Regular";
            description = "The normal variant of the font family";
          };

          bold = mkOption {
            type = types.str;
            example = "Bold";
            default = "Bold";
            description = "The bold variant of the font family";
          };

          italic = mkOption {
            type = types.str;
            example = "Italic";
            default = "Italic";
            description = "The italic variant of the font family";
          };

          bold_italic = mkOption {
            type = types.str;
            example = "Bold Italic";
            default = "Bold Italic";
            description = "The bold italic variant of the font family";
          };
        };
      };
      inherit description;
    };
in
{
  options.fonts = {
    serif = mkFontFamily { description = "Serif font family"; };
    sansSerif = mkFontFamily { description = "Sans serif font family"; };
    monospace = mkFontFamily { description = "Monospace font family"; };
    emoji = mkFontFamily { description = "Emoji font family"; };
  };

  config = {
    fonts.fontconfig = {
      enable = pkgs.stdenv.isLinux;

      defaultFonts = {
        serif = [ cfg.serif.name ];
        sansSerif = [ cfg.sansSerif.name ];
        monospace = [ cfg.monospace.name ];
        emoji = [ cfg.emoji.name ];
      };
    };

    home.packages = [
      cfg.serif.package
      cfg.sansSerif.package
      cfg.monospace.package
      cfg.emoji.package
    ];
  };
}
