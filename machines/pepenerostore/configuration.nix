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
    hostName = "pepenerostore";
    firewall = {
      allowedTCPPorts = [ 80 443 ];
    };
  };

  programs.fish = {
    enable = true;
  };

  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    virtualHosts."pepenerostore.it" = {
      # addSSL = true;
      # enableACME = true;
      root = "/home/nix/pepenerostore";
    };
  };
}
