{ modulesPath, pkgs, user, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/digital-ocean-config.nix")
  ];

  users.users."nix" = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    home = "/home/nix";
    shell = pkgs.fish;
  };

  security.sudo = {
    wheelNeedsPassword = false;
  };

  networking = {
    hostName = "treed-main";
    firewall = {
      allowedTCPPorts = [ 80 5000 ];
    };
  };

  programs.fish = {
    enable = true;
  };

  services.nginx = {
    enable = true;
  };
}