{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.skhd;
in
{
  meta.maintainers = [ maintainers.noib3 ];

  options.programs.skhd = {
    enable = mkEnableOption "skhd";

    package = mkOption {
      type = types.package;
      default = pkgs.skhd;
      defaultText = literalExample "pkgs.skhd";
      description = "The skhd package to use.";
    };

    config = mkOption {
      type = types.lines;
      default = "";
      example = literalExample ''
        alt - up : yabai -m window --focus north
        alt - down : yabai -m window --focus south
        alt - left : yabai -m window --focus west
        alt - right : yabai -m window --focus east
        alt + shift - f : yabai -m window --toggle float
      '';
      description = "Contents of <filename>skhdrc</filename>.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "skhd/skhdrc".text = cfg.config;
    };
  };
}
