{ modulesPath, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> { };

  user-passwords = {
    "noib3" = lib.strings.removeSuffix "\n"
      (builtins.readFile ./secrets/users.noib3.pwd);
    "couchdb" = lib.strings.removeSuffix "\n"
      (builtins.readFile ./secrets/users.couchdb.pwd);
  };

  configs = {
    couchdb =
      (import ../../defaults/couchdb { inherit lib; })
      // (import ./overrides/couchdb.nix);
    syncthing = import ./overrides/syncthing.nix;
  };
in
{
  imports = [
    (modulesPath + "/virtualisation/digital-ocean-config.nix")
  ];

  swapDevices = [
    {
      device = "/var/swap";
      size = 2048;
    }
  ];

  users = {
    mutableUsers = false;
    users = {
      "noib3" = {
        home = "/home/noib3";
        shell = pkgs.fish;
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keyFiles = [
          ./ssh-authorized-keys/noib3.pub
        ];
        password = user-passwords.noib3;
      };

      "couchdb" = {
        home = "/home/couchdb";
        shell = pkgs.fish;
        isSystemUser = true;
        createHome = true;
        extraGroups = [ "couchdb" ];
        password = user-passwords.couchdb;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    vim
  ];

  security.sudo = {
    wheelNeedsPassword = false;
  };

  networking = {
    hostName = "archiv3";
    firewall = {
      allowedTCPPorts = [
        5984
        8384
      ];
    };
  };

  programs.fish = {
    enable = true;
  };

  services.couchdb = {
    enable = true;
    package = unstable.couchdb3;
  } // configs.couchdb;

  services.syncthing = {
    enable = true;
    package = unstable.syncthing;
  } // configs.syncthing;
}
