{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> { };

  user-passwords = {
    "noib3" = lib.strings.removeSuffix "\n"
      (builtins.readFile ./secrets/users.noib3.pwd);
    "couchdb" = lib.strings.removeSuffix "\n"
      (builtins.readFile ./secrets/users.couchdb.pwd);
  };

  configs = {
    couchdb = import ../../defaults/couchdb { inherit lib; };
    syncthing = import ./overrides/syncthing.nix;
    transmission = import ./overrides/transmission.nix;
  };

  falloutGrubTheme = pkgs.fetchgit {
    url = "https://github.com/shvchk/fallout-grub-theme.git";
    rev = "fe27cbc99e994d50bb4269a9388e3f7d60492ffa";
    sha256 = "1z8zc4k2mh8d56ipql8vfljvdjczrrna5ckgzjsdyrndfkwv8ghw";
  };
in
{
  imports = [
    /etc/nixos/hardware-configuration.nix
  ];

  console.keyMap = "us";
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Rome";

  users = {
    mutableUsers = false;

    users."noib3" = {
      home = "/home/noib3";
      shell = pkgs.fish;
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "input"
        "plugdev"
      ];
      password = user-passwords.noib3;
    };

    users."couchdb" = {
      home = "/home/couchdb";
      shell = pkgs.fish;
      isSystemUser = true;
      createHome = true;
      extraGroups = [ "couchdb" ];
      password = user-passwords.couchdb;
    };
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
  ];

  boot = {
    consoleLogLevel = 0;
    kernelParams = [ "quiet" "udev.log_priority=3" ];
    # Only available in the unstable branch for now. See [1].
    # initrd.verbose = false;

    loader.grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      useOSProber = true;
      gfxmodeEfi = "1920x1080";
      gfxmodeBios = "1920x1080";
      splashImage = "${falloutGrubTheme}/background.png";
      extraConfig = ''
        set theme=($drive1)//themes/fallout-grub-theme/theme.txt
      '';
    };

    loader.efi.canTouchEfiVariables = true;
  };

  system.activationScripts.copyGrubTheme = ''
    mkdir -p /boot/themes
    cp -R ${falloutGrubTheme}/ /boot/themes/fallout-grub-theme
  '';

  hardware.bluetooth = {
    enable = true;
  };

  hardware.openrazer = {
    enable = true;
  };

  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };

  networking = {
    hostName = "blade";
    useDHCP = false;
    interfaces.enp2s0.useDHCP = true;
    networkmanager.enable = true;
    firewall.allowedTCPPorts = [
      8384
    ];
  };

  security.sudo = {
    wheelNeedsPassword = false;
  };

  sound = {
    enable = true;
  };

  programs.fish = {
    enable = true;
  };

  programs.xss-lock = {
    enable = true;
  };

  services.couchdb = {
    enable = true;
    package = unstable.couchdb3;
  } // configs.couchdb;

  services.geoclue2 = {
    enable = true;
  };

  services.syncthing = {
    enable = true;
    package = unstable.syncthing;
  } // configs.syncthing;

  services.tlp = {
    enable = true;
  };

  services.transmission = {
    enable = true;
  } // configs.transmission;

  services.udisks2 = {
    enable = true;
  };

  services.udev = {
    extraHwdb = ''
      evdev:input:b0003v1532p026F*
       KEYBOARD_KEY_700e2=leftmeta
       KEYBOARD_KEY_700e3=leftalt
       KEYBOARD_KEY_700e6=rightmeta
    '';
  };

  services.xserver = {
    enable = true;
    autoRepeatDelay = 150;
    autoRepeatInterval = 33;
    layout = "us";
    # videoDrivers = [ "nvidia" ];

    libinput = {
      enable = true;
      naturalScrolling = true;
      disableWhileTyping = true;
    };

    displayManager = {
      defaultSession = "none+bspwm";
      autoLogin = {
        enable = true;
        user = "noib3";
      };
    };

    windowManager = {
      bspwm.enable = true;
    };

    # This together with 'xset s off'should disable every display power
    # management option. See [2] and [3] for more infos.
    config = ''
      Section "Extensions"
          Option "DPMS" "off"
      EndSection
    '';
  };

  system.stateVersion = "20.09";
}

# [1]: https://github.com/NixOS/nixpkgs/issues/32555
# [2]: https://wiki.archlinux.org/index.php/Display_Power_Management_Signaling
# [3]: https://shallowsky.com/linux/x-screen-blanking.html
