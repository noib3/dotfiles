{ modulesPath, lib, pkgs, ... }:

let
  unstable = import <nixos-unstable> { };
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
    users = {
      "noib3" = {
        home = "/home/noib3";
        shell = pkgs.fish;
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+p7HMx7J6erLtpJtl1AZjoZvuRMnLwaCWHfaJW3QPolMyI7GQNbJ4jkRRiMWWqHFLy0CLb4gCNYz34BZdqqq8y+RPdb2yju/uTJjzceMBt3N7GuF82KAFeGXS5VCkX/wjOoJVEO4hgIVbkCixSjqIpzDvOlX7FBwVypZAeKffWSUOI5Fdal5KTtgpSF1BEV2vHtDffmF869webuBz/stcAfH/CNnzbyyBKk0UVnvUE6shphf0+ndpR3LV1EAyEiOcPNFOs0cfddO2NFswm1e1tGAFOzgp4ECRDDm5ou8qOUR+cqhBnKzOsQwlnN2dlOCTbB33dW7p07J4nKpfcdMkh7uNQ8gjUjGWe/OtdXUUQWbztGgbGavMLGEiT5XAtbABGgiHmnLd72AbpUJ9kO8CLbpwePbay0MgVETHAxv0OUdz/DpWFrbCKEZ9hWVnAacJ1Iv5ClpODC2p6U2rHHXy8PTcbi2FX9kqA9mHJcqujEbWrfDxl5gxoBThptIWoE9vp/sC5c92WOGZa1mlH+f9doKp6FMz+U5BzZTEaAPVUeACzr7PpeK+d8aS3bnz8XAKSJZMlpflJKM7kFqAZ4HXRIrbb7ITEbKdozd/YmSr6OB6UwMsXVlKKEBcw/gH0aqb0y6w44khltiQQyCXeiWnJydwLwRzUTvxnlCBpaePnQ== openpgp:0x919FC55F"
        ];
      };

      "couchdb" = {
        home = "/home/couchdb";
        shell = pkgs.fish;
        isSystemUser = true;
        createHome = true;
        extraGroups = [ "couchdb" ];
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
    hostName = "archive";
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
    user = "couchdb";
    group = "couchdb";
    databaseDir = "/home/couchdb/couchdb";
    bindAddress = "0.0.0.0";
  };

  services.syncthing = {
    enable = true;
    package = unstable.syncthing;
    declarative = {
      overrideDevices = false;
      overrideFolders = false;
    };
    user = "noib3";
    dataDir = "/home/noib3";
    configDir = "/home/noib3/.config/syncthing";
    guiAddress = "0.0.0.0:8384";
  };
}
