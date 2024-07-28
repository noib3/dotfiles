# System-wide config shared by every host.

{ config
, lib
, pkgs
, homedir ? "/home/${username}"
, hostname ? "nixos"
, username ? "noib3"
}:

{
  boot = {
    consoleLogLevel = 0;

    extraModulePackages = with config.boot.kernelPackages; [
      # Enables virtual video devices. Used to use OBS in video calls.
      v4l2loopback
    ];

    kernelModules = [
      "v4l2loopback"
    ];

    kernelParams = [
      "quiet"
    ];
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
    scripts.website-blocker
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  hardware.bluetooth = {
    enable = true;
  };

  hardware.graphics = {
    enable = true;
  };

  nix.settings =  {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    trusted-substituters = [
      "https://cache.soopy.moe"
      "https://nix-community.cachix.org"
    ];
  };

  networking = {
    hostName = hostname;
    networkmanager.enable = true;
  };

  # See https://evanrelf.com/nixos-fix-command-not-found-database-file-error
  programs.command-not-found.enable = false;

  programs.fish = {
    enable = true;
  };

  programs.hyprland.enable = true;

  # programs.nm-applet = {
  #   enable = true;
  # };

  security.sudo.wheelNeedsPassword = false;

  services.block-domains = {
    enable = true;
    blocked = [
      "youtube.com"
      "twitch.tv"
      "x.com"
    ];
    blockAt = "08:00";
    unblockAt = "20:00";
  };

  # services.blueman = {
  #   enable = true;
  # };

  # services.geoclue2 = {
  #   enable = true;
  # };

  services.getty.autologinUser = username;

  services.greetd =
  let
    hyprland = "${pkgs.hyprland}/bin/Hyprland";
    tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
  in {
    enable = true;
    settings = {
      initial_session = {
        command = "${hyprland}";
        user = username;
      };
      default_session = {
        command = ''
          ${tuigreet} \
            --greeting "Welcome to NixOS!" --asterisks --remember \
            --remember-user-session --time -cmd ${hyprland}
        '';
        user = "greeter";
      };
    };
  };

  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      disableWhileTyping = true;
    };
  };

  # services.tlp = {
  #   enable = true;
  # };

  # services.transmission = {
  #   enable = true;
  # } // (import "${configDir}/transmission" {
  #   inherit pkgs username homeDirectory;
  # });

  # services.udisks2 = {
  #   enable = true;
  # };

  # services.udev = {
  #   extraHwdb = ''
  #     evdev:input:b0003v1532p026F*
  #      KEYBOARD_KEY_700e2=leftmeta
  #      KEYBOARD_KEY_700e3=leftalt
  #      KEYBOARD_KEY_700e6=rightmeta
  #   '';
  # };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  systemd.user = {
    services.auto-start-solaar = {
      enable = true;
      description = ''
        Start Solaar to enable custom settings for Logitech devices
      '';
      after = [ "graphical-session.target" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.solaar}/bin/solaar --window=hide";
      };
    };
  };

  time.timeZone = "Asia/Singapore";

  users.users."${username}" = {
    home = homedir;
    shell = pkgs.fish;
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
}
