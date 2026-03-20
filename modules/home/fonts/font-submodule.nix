{ lib }:

with lib;
types.submodule {
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
      type = types.submodule {
        freeformType = types.attrsOf types.float;
        options.default = mkOption {
          type = types.float;
          description = "The default font size, used when no program-specific override exists";
        };
      };
      example = {
        default = 16.5;
        ghostty = 14.0;
      };
      description = "Font sizes keyed by program name";
    };
  };
}
