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

  systemd.services = {
    treed-gunicorn = {
      description = "Gunicorn instance to serve treed.";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      # serviceConfig = {
      #   User = "nix";
      #   ExecStart = "/home/nix/.cache/pypoetry/virtualenvs/treed-77-me7yV-py3.8/bin/gunicorn --workers 3 --bind 0.0.0.0:5000 treed.wsgi:app";
      # };
    };
  };
}
