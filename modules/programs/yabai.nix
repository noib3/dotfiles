{ config, lib, pkgs, ... }:

# Adapted from [1].

with lib;
let
  cfg = config.programs.yabai;

  toYabaiConfig = opts:
    concatStringsSep "\n" (mapAttrsToList
      (p: v:
        "yabai -m config ${p} ${toString v}")
      opts);
in
{
  meta.maintainers = [ maintainers.noib3 ];

  options.programs.yabai = {
    enable = mkEnableOption "yabai";

    package = mkOption {
      type = types.package;
      default = pkgs.yabai;
      defaultText = literalExample "pkgs.yabai";
      description = "The yabai package to use.";
    };

    config = mkOption {
      type = types.attrs;
      default = { };
      example = literalExample ''
        {
          focus_follows_mouse = "autoraise";
          mouse_follows_focus = "off";
          window_placement = "second_child";
          window_opacity = "off";
          top_padding = 36;
          bottom_padding = 10;
          left_padding = 10;
          right_padding = 10;
          window_gap = 10;
        }
      '';
      description = ''
        Key/Value pairs to pass to yabai's 'config' domain, via the configuration file.
      '';
    };

    extraConfig = mkOption {
      type = types.str;
      default = "";
      example = literalExample ''
        echo "yabai config loaded..."
      '';
      description = ''
        Extra arbitrary configuration to append to the configuration file.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "yabai/yabairc" = {
        text = (
          if (cfg.config != { }) then "${toYabaiConfig cfg.config}"
          else ""
        ) + optionalString (cfg.extraConfig != "") ("\n" + cfg.extraConfig);
        executable = true;
      };
    };
  };
}

# [1]: https://github.com/LnL7/nix-darwin/blob/master/modules/services/yabai/default.nix
