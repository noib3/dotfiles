{
  config,
  lib,
  pkgs,
  hostName,
  userName,
  ...
}:

let
  common = import ../common {
    inherit
      config
      lib
      pkgs
      hostName
      userName
      ;
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
    common
  ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/efi";
      systemd-boot.enable = true;
    };
  };

  caches.cachix.enable = true;

  hardware = {
    apple.macbook-pro-15-1.enable = true;
    logitech.mx-master-3s-for-mac.enable = true;
  };

  # This option defines the first version of NixOS installed on this particular
  # machine, and should NEVER be changed after the initial install.
  system.stateVersion = "24.11";
}
