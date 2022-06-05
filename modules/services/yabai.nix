{ config
, lib
, pkgs
, ...
}:

with lib;
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  cfg = config.services.yabai;

  toYabaiConfig = opts:
    concatStringsSep "\n" (mapAttrsToList
      (p: v:
        "${pkgs.yabai}/bin/yabai -m config ${p} ${toString v}")
      opts);
in
{
  options.services.yabai = {
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

  config = mkMerge [
    {
      assertions = [
        {
          assertion = cfg.enable -> isDarwin;
          message = "yabai is only supported on Darwin";
        }
      ];
    }

    (mkIf cfg.enable {
      home.packages = [ cfg.package ];

      xdg.configFile."yabai/yabairc" = {
        text =
          (optionalString (cfg.config != { }) "${toYabaiConfig cfg.config}")
          + (optionalString (cfg.extraConfig != "") ("\n" + cfg.extraConfig));

        executable = true;

        onChange =
          "${pkgs.bash}/bin/bash ${config.xdg.configHome}/yabai/yabairc";
      };

      launchd.agents.yabai = {
        enable = lib.mkDefault true;
        config = {
          ProgramArguments = [
            "${cfg.package}/bin/yabai"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          ProcessType = "Interactive";
          EnvironmentVariables = {
            PATH = "${config.home.homeDirectory}/.nix-profile/bin";
          };
          Nice = 20;
          StandardOutPath = "${config.xdg.cacheHome}/yabai.out.log";
          StandardErrorPath = "${config.xdg.cacheHome}/yabai.err.log";
        };
      };
    })
  ];

  # config = mkIf cfg.enable {
  #   home.packages = [ cfg.package ];

  #   xdg.configFile = {
  #     "yabai/yabairc" = {
  #       text = (
  #         if (cfg.config != { }) then "${toYabaiConfig cfg.config}"
  #         else ""
  #       ) + optionalString (cfg.extraConfig != "") ("\n" + cfg.extraConfig);
  #       executable = true;
  #     };
  #   };
  # };

  meta.maintainers = [ maintainers.noib3 ];
}
