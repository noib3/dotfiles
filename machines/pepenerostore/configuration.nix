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

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."pepenerostore.it" = {
      enableACME = true;
      forceSSL = true;
      root = "/home/nix/pepenerostore";
    };
  };

  security.acme = {
    acceptTerms = true;
    certs = {
      "pepenerostore.it".email = "info@pepenerostore.it";
    };
  };

  systemd.services.nginx = {
    serviceConfig.ProtectHome = "read-only";
  };
}
