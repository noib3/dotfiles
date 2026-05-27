{
  config,
  pkgs,
  lib,
  inputs,
  system,
  username,
  ...
}:

let
  generatorsSrc = inputs.nixpkgs.legacyPackages.${system}.nixos-generators.src;
in
{
  imports = [
    "${generatorsSrc}/all-formats.nix"
  ];

  environment.systemPackages = with pkgs; [
    git
    inputs.home-manager.packages.${system}.default
    neovim
  ];

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  networking = {
    inherit (config.machines.current) hostName;
    useDHCP = false;
    useNetworkd = true;
  };

  systemd.network.networks."10-dhcp" = {
    matchConfig.Name = [
      "en*"
      "eth*"
    ];
    networkConfig.DHCP = "yes";
  };

  nix.settings = {
    experimental-features = [
      "flakes"
      "nix-command"
      "pipe-operators"
    ];
    trusted-users = [
      "root"
      username
    ];
    use-xdg-base-directories = true;
    warn-dirty = false;
  };

  programs = {
    command-not-found.enable = false;
    fish.enable = true;
  };

  security.sudo.wheelNeedsPassword = false;

  services = {
    cloud-init = {
      enable = true;
      network.enable = true;
      settings.users = [
        "default"
        {
          name = username;
          groups = [ "wheel" ];
          shell = lib.getExe config.users.users.${username}.shell;
          sudo = [ "ALL=(ALL) NOPASSWD:ALL" ];
        }
      ];
    };

    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };

    cloud-init.settings.preserve_hostname = true;
  };

  users.users.${username} = {
    isNormalUser = lib.mkDefault true;
    extraGroups = [ "wheel" ];
    home = "/home/${username}";
    shell = pkgs.fish;
  };

  system.stateVersion = "25.11";
}
