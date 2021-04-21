{ modulesPath, pkgs, user, ... }:
let
  unstable = import <nixos-unstable> { };

  configs = {
    couchdb = import ./overrides/couchdb.nix;
    syncthing = import ./overrides/syncthing.nix;
  };
in
{
  imports = [
    (modulesPath + "/virtualisation/digital-ocean-config.nix")
  ];

  users.users = {
    "nix" = {
      home = "/home/nix";
      shell = pkgs.fish;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };

    "couchdb" = {
      home = "/home/couchdb";
      shell = pkgs.fish;
      isSystemUser = true;
      createHome = true;
      extraGroups = [ "couchdb" ];
    };
  };

  security.sudo = {
    wheelNeedsPassword = false;
  };

  networking = {
    hostName = "sync";
    firewall = {
      allowedTCPPorts = [ 8384 ];
    };
  };

  programs = {
    fish = {
      enable = true;
    };
  };

  services = {
    couchdb = {
      enable = true;
      package = unstable.couchdb3;
    } // configs.couchdb;

    syncthing = {
      enable = true;
      package = unstable.syncthing;
    } // configs.syncthing;
  };
}
