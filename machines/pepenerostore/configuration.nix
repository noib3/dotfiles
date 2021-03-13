{ modulesPath, pkgs, user, ... }:
let
  unstable = import <nixos-unstable> { };
in
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
      allowedTCPPorts = [ 8384 ];
    };
  };

  programs.fish = {
    enable = true;
  };
}
