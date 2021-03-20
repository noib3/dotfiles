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
        set modeindicator false
        bind j scrollline 5
        bind k scrollline -5
      '';
      description = ''
        Configuration written to
        <filename>~/.config/tridactyl/tridactylrc</filename>.
      '';
    };

    themes = mkOption {
      type = types.attrsOf types.lines;
      default = { };
      example = literalExample ''
        {
          theme = \'\'
            :root {
              --tridactyl-hint-bg: none;
              --tridactyl-hint-outline: none;
              --tridactyl-hint-active-bg: none;
              --tridactyl-hint-active-outline: none;
            }
          \'\';
        }
      '';
      description = ''
        Theme files written to
        <filename>~/.config/tridactyl/themes/<theme>.css</filename>.
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile = {
      "tridactyl/tridactylrc".text = cfg.config;
    } // mapAttrs'
      (name: value: nameValuePair
        ("tridactyl/themes/${name}.css")
        ({ text = value; })
      )
      cfg.themes;
  };
}
