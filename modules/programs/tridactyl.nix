{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.tridactyl;
in
{
  meta.maintainers = [ maintainers.noib3 ];

  options.programs.tridactyl = {
    enable = mkEnableOption "tridactyl";

    config = mkOption {
      type = types.lines;
      default = "";
      example = literalExample ''
        qwe
      '';
      description = ''
        Contents of <filename>~/.config/tridactyl/tridactylrc</filename>.
      '';
    };

    themes = mkOption {
      type = types.attrsOf types.lines;
      default = { };
      example = literalExample ''
        qwe
      '';
      description = "Contents of";
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile = {
      "tridactyl/tridactylrc".text = cfg.config;
    } // mapAttrs'
      (
        name: value: nameValuePair
          ("tridactyl/themes/${name}.css")
          ({ text = value; })
      )
      cfg.themes;
  };
}

# if nativeMessenger is true execute the following command:
# curl -fsSl https://raw.githubusercontent.com/tridactyl/native_messenger/master/installers/install.sh -o /tmp/trinativeinstall.sh && sh /tmp/trinativeinstall.sh master
