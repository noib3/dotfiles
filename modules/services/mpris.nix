{ config, lib, pkgs, ... }:

with lib;
{
  meta.maintainers = [ maintainers.noib3 ];

  options = {
    services.mpris = {
      enable = mkEnableOption "Programmatic API for controlling media players";
    };
  };

  config = mkIf config.services.mpris.enable {
    systemd.user.services.mpris-proxy = {
      Unit.Description = "Mpris proxy";
      Unit.After = [ "network.target" "sound.target" ];
      Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
      Install.WantedBy = [ "default.target" ];
    };
  };
}
