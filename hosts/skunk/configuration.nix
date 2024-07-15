{ config, lib, pkgs, ... }:

let
  common = import ../common.nix {
    inherit lib pkgs;
    hostname = "skunk";
  };
in
{
  imports = [
    ./hardware-configuration.nix
    common
  ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi";
      systemd-boot.enable = true;
    };
  };

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

  # This option defines the first version of NixOS installed on this particular
  # machine, and should NEVER be changed after the initial install.
  system.stateVersion = "24.11";
}
