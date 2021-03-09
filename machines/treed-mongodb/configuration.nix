{ modulesPath, lib, pkgs, user, ... }:

{
  imports = lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix ++ [
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
    hostName = "treed-mongodb";
    firewall = {
      allowedTCPPorts = [ 80 5000 ];
    };
  };

  programs.fish = {
    enable = true;
  };

  services.mongodb = {
    enable = true;
  };
}
