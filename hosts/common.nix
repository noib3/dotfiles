# System-wide config shared by every host.

{ lib
, pkgs
, homedir ? "/home/${username}"
, hostname ? "nixos"
, username ? "noib3"
}:

{
  boot = {
    consoleLogLevel = 0;
    kernelParams = [
      "quiet"
    ];
  };

  console.keyMap = "us";

  environment.systemPackages = [
    pkgs.git
    pkgs.neovim
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  hardware.bluetooth = {
    enable = true;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  ];

  networking = {
    hostName = hostname;
    networkmanager.enable = true;
  };

  security.sudo.wheelNeedsPassword = false;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  time.timeZone = "Asia/Singapore";

  users.users."${username}" = {
    home = homeDirectory;
    shell = pkgs.fish;
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
}
