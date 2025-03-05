{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.desktop;
in
{
  options.modules.desktop = {
    enable = mkEnableOption "Desktop config";
    hostName = mkOption {
      type = types.str;
      example = "macbook-pro";
      description = "The hostname of the machine";
    };
    userName = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    boot = {
      consoleLogLevel = 0;

      extraModulePackages = with config.boot.kernelPackages; [
        # Enables virtual video devices. Used to use OBS in video calls.
        v4l2loopback
      ];

      kernelModules = [ "v4l2loopback" ];

      kernelParams = [ "quiet" ];
    };

    # boot = {
    #   consoleLogLevel = 0;
    #   kernelParams = [
    #     "quiet"
    #     "udev.log_priority=3"
    #     "button.lid_init_state=open"
    #     "vt.cur_default=0x700010"
    #   ];
    #
    #   initrd.verbose = false;
    #
    #   loader.grub = {
    #     enable = true;
    #   } // (import "${configDir}/grub" {
    #     inherit pkgs machine colorscheme palette hexlib;
    #   });
    #
    #   loader.efi.canTouchEfiVariables = true;
    # };

    console.keyMap = "us";

    environment.systemPackages = with pkgs; [
      git
      home-manager
      neovim
      config.scripts.website-blocker
    ];

    i18n.defaultLocale = "en_US.UTF-8";

    hardware.bluetooth = {
      enable = true;
      settings = {
        General = {
          DiscoverableTimeout = 0;
          FastConnectable = true;
        };
      };
    };

    hardware.graphics = {
      enable = true;
    };

    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        cfg.userName
      ];
      warn-dirty = false;
    };

    networking = {
      inherit (cfg) hostName;
      networkmanager.enable = true;
    };

    # See https://evanrelf.com/nixos-fix-command-not-found-database-file-error
    programs.command-not-found.enable = false;

    programs.fish = {
      enable = true;
    };

    programs.hyprland.enable = true;

    security.sudo.wheelNeedsPassword = false;

    services.block-domains = {
      enable = true;
      blocked = [
        "youtube.com"
        "twitch.tv"
        "x.com"
      ];
      blockAt = [
        "8:00"
        "14:00"
      ];
      unblockAt = [
        "13:00"
        "20:00"
      ];
    };

    services.getty.autologinUser = cfg.userName;

    services.libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        disableWhileTyping = true;
      };
    };

    services.automatic-timezoned = {
      enable = true;
    };

    services.mullvad-vpn = {
      enable = true;
    };

    # services.transmission = {
    #   enable = true;
    # } // (import "${configDir}/transmission" {
    #   inherit pkgs username homeDirectory;
    # });

    # Needed by `udiskie`.
    services.udisks2.enable = true;

    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };

    users.users."${cfg.userName}" = {
      home = "/home/${cfg.userName}";
      shell = pkgs.fish;
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };
  };
}
