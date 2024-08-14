{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.fontFamily;
in
{
  options.fontFamily = {
    name = mkOption {
      type = types.str;
      default = "";
      example = "FiraCode Nerd Font";
      description = "Name of the font family";
    };

    nerdfontsName = mkOption {
      type = types.str;
      default = "";
      example = "FiraCode";
      description = "Name of the Nerd Font";
    };

    size = mkOption {
      type = types.float;
      default = 16;
      example = 18;
      description = "Size of the font";
    };

    alacritty = mkOption {
      type = types.submodule {
        options = {
          bold_italic = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "Bold Italic";
            description = "The variant to use for a bold italic font";
          };
        };
      };
      default = { };
      example = {
        bold_italic = "Bold Italic";
      };
    };

    qutebrowser = mkOption {
      type = types.submodule {
        options = {
          default_size = mkOption {
            type = types.float;
            default = cfg.size;
            example = 18;
            description = "Qutebrowser's default font size";
          };
        };
      };
      default = {
        default_size = cfg.size;
      };
    };
  };

  config = mkIf (cfg.name != "") {
    fonts.fontconfig.enable = true;
    home.packages = [ (pkgs.nerdfonts.override { fonts = [ cfg.nerdfontsName ]; }) ];
  };
}
