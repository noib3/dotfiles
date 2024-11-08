{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.hardware.apple.macbook-pro-15-1;
in
{
  options.hardware.apple.macbook-pro-15-1 = {
    enable = mkEnableOption ''
      Enables configurations for the MacBook Pro 15,1
    '';
  };

  config = mkIf cfg.enable {
    caches.apple-t2.enable = true;

    hardware.firmware = [
      (pkgs.stdenvNoCC.mkDerivation (final: {
        name = "broadcom-firmware";
        # Contains the Broadcom Bluetooth and WiFi firmware, and can be
        # downloaded by executing this script:
        # https://wiki.t2linux.org/tools/firmware.sh
        src = ./firmware.tar;
        dontUnpack = true;
        installPhase = ''
          mkdir -p $out/lib/firmware/brcm
          tar -xf ${final.src} -C $out/lib/firmware/brcm
        '';
      }))
    ];

    # Leaving these set to "suspend" (the default) causes the system to remain
    # in an unresponsive state when the lid is re-opened.
    services.logind = {
      lidSwitch = "lock";
      lidSwitchExternalPower = "lock";
    };
  };
}
