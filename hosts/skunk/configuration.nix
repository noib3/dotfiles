{ config
, lib
, pkgs
, colorscheme
, font
, ...
}:

let
  hexlib = import ../../lib/hex.nix { inherit lib; };
  palette = import (../../palettes + "/${colorscheme}.nix");

  common = import ../common.nix {
    inherit config lib pkgs;
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

  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };

  # Setting these to "suspend", which is the default, causes the system to
  # remain in an unresponsive state when the lid is re-opened.
  services.logind = {
    lidSwitch = "lock";
    lidSwitchExternalPower = "lock";
  };

  # This option defines the first version of NixOS installed on this particular
  # machine, and should NEVER be changed after the initial install.
  system.stateVersion = "24.11";
}
