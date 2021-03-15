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
    hostName = "sync";
    firewall = {
      allowedTCPPorts = [ 8384 ];
    };
  };

  programs.fish = {
    enable = true;
  };

  services.syncthing = {
    enable = true;
    package = unstable.syncthing;
    user = "nix";
    dataDir = "/home/nix";
    configDir = "/home/nix/.config/syncthing";
    guiAddress = "0.0.0.0:8384";
    declarative = {
      # devices = {
      #   mbair = {
      #     name = "MacBook Air";
      #     id = "V2JGYER-MUHWW7U-435IRVJ-4PTEXWD-OO3R3KM-5R5V5ZN-JJOFNC7-CRFENAA";
      #   };
      #   oneplus = {
      #     name = "OnePlus Nord";
      #     id = "MLUZ3TB-SCXVHEX-CKYU7IF-CUTRR2I-UIVCPTO-TQFNRWY-COD6CCN-US5JYQP";
      #   };
      # };

      # folders = {
      #   Sync = {
      #     path = "/home/nix/Sync";
      #     id = "qu7hn-unrno";
      #     label = "Sync";
      #     rescanInterval = 10;
      #     type = "sendreceive";
      #     ignorePerms = false;
      #   };
      #   Camera = {
      #     path = "/home/nix/Media/OnePlus-Nord/Camera";
      #     id = "qu7hn-unrno";
      #     label = "Sync";
      #     rescanInterval = 10;
      #     type = "receiveonly";
      #     ignorePerms = false;
      #   };
      # };
      overrideDevices = false;
      overrideFolders = false;
    };
  };
}
