{
  colorscheme,
  homeManagerMachinesModule,
  hostname,
  inputs,
  nixosGeneratorsSrc,
  pkgs,
  system,
  username,
  ...
}:

{
  imports = [
    "${nixosGeneratorsSrc}/all-formats.nix"
    inputs.home-manager.nixosModules.home-manager
  ];

  environment.systemPackages = with pkgs; [
    git
    neovim
  ];

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "ookla-speedtest"
      "proton-pass"
      "proton-vpn-cli"
      "signal-desktop"
      "widevine-cdm"
      "zoom"
    ];

  networking = {
    hostName = hostname;
    useDHCP = true;
  };

  nix.settings = {
    experimental-features = [
      "flakes"
      "nix-command"
      "pipe-operators"
    ];
    trusted-users = [
      "root"
      username
    ];
    use-xdg-base-directories = true;
    warn-dirty = false;
  };

  programs = {
    command-not-found.enable = false;
    fish.enable = true;
  };

  security.sudo.wheelNeedsPassword = false;

  services = {
    cloud-init = {
      enable = true;
      network.enable = true;
      settings.users = [
        "default"
        {
          name = username;
          groups = [ "wheel" ];
          shell = "${pkgs.fish}/bin/fish";
          sudo = [ "ALL=(ALL) NOPASSWD:ALL" ];
        }
      ];
    };

    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    home = "/home/${username}";
    shell = pkgs.fish;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.${username} = {
      imports = [
        ../../home
        homeManagerMachinesModule
        {
          home.username = username;
          machines.current.name = hostname;
          machines.current.system = system;
          modules.colorschemes.${colorscheme}.enable = true;
        }
      ];
    };
  };

  system.stateVersion = "25.11";
}
