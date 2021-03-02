{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.fd;

in
{
  meta.maintainers = [ maintainers.noib3 ];

  options.programs.fd = {
    enable = mkEnableOption ''
      fd, A simple, fast and user-friendly alternative to 'find'
    '';

    ignores = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "**/.git"
        "*/.aux"
      ];
      description = ''
        Contents of the global ignore file.
      '';
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.fd ];

    xdg.configFile."fd/ignore" = mkIf (cfg.ignores != [ ]) {
      text = concatStringsSep "\n" cfg.ignores + "\n";
    };
  };
}
