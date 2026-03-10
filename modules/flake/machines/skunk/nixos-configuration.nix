{
  hostname,
  username,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../../nixos
  ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi";
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
    inherit hostname username;
  };

  system.stateVersion = "24.11";
}
