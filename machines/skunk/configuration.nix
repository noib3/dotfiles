{
  config,
  lib,
  pkgs,
  hostName,
  userName,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
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
    remarkable.remarkable2.enable = true;
  };

  modules.desktop = {
    enable = true;
    inherit hostName userName;
  };

  # This option defines the first version of NixOS installed on this particular
  # machine, and should NEVER be changed after the initial install.
  system.stateVersion = "24.11";
}
