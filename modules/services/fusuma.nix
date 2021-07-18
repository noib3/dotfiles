{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.fusuma;
  yaml = pkgs.formats.yaml { };

  # json = pkgs.writeText "config.json" (builtins.toJSON cfg.settings);
  # cfgyaml = pkgs.runCommand "configuration.yaml" { preferLocalBuild = true; } ''
  #   ${pkgs.remarshal}/bin/json2yaml -i ${json} -o $out
  # '';

in
{
  options.services.fusuma = {
    enable = mkEnableOption "Enable fusuma service";

    package = mkOption {
      type = types.package;
      default = pkgs.fusuma;
      defaultText = literalExample "pkgs.fusuma";
      description = "The fusuma package to install.";
    };

    settings = mkOption {
      type = yaml.type;
      default = { };
      example = literalExample ''
        {
          swipe = {
            "3" = {
              left.command = "xdotool key shift+l";
              right.command = "xdotool key shift+h";
            };
          };
        }
      '';
      description = ''
        Configuration written to
        <filename>~/.config/fusuma/config.yml</filename>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # xdg.configFile = {
    #   "fusuma/config.yml".source = cfgyaml;
    # };

    xdg.configFile = {
      "fusuma/config.yml".source =
        yaml.generate "config.yml" cfg.settings;
    };

    systemd.user.services.fusuma = {
      Unit = {
        Description = "Fusuma multitouch gesture recognizer";
      };

      Service = {
        ExecStart = "${cfg.package}/bin/fusuma";
      };

      Install = {
        WantedBy = [ "graphical.target" ];
      };
    };
  };

  meta.maintainers = with lib.maintainers; [
    noib3
  ];
}
