{ config, pkgs, ... }:
let
  unstable = import <nixos-unstable> { };
in
{
  imports = [
    /etc/nixos/hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  sound.enable = true;

  hardware = {
    bluetooth.enable = true;
    openrazer.enable = true;

    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
    };
  };

  users.users.noib3 = {
    isNormalUser = true;
    home = "/home/noib3";
    shell = pkgs.fish;
    # The plugdev group is needed by the openrazer-daemon service.
    # See https://openrazer.github.io/#project for more details.
    extraGroups = [ "wheel" "plugdev" ];
  };

  security.sudo = {
    wheelNeedsPassword = false;
  };

  networking = {
    hostName = "blade";
    useDHCP = false;
    interfaces.enp2s0.useDHCP = true;
    networkmanager.enable = true;
    firewall = {
      allowedTCPPorts = [ 8384 ];
    };
  };

  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  environment.systemPackages = with pkgs; [
    evemu
    evtest
    gcc
    git
    libinput-gestures
    vim
  ];

  programs.fish = {
    enable = true;
  };

  services.logind = {
    extraConfig = ''
      IdleAction=ignore
    '';
  };

  services.xserver = {
    enable = true;
    layout = "us";

    # Length of time in milliseconds that a key must be depressed before
    # autorepeat starts.
    autoRepeatDelay = 140;

    # Length of time in milliseconds that should elapse between
    # autorepeat-generated keystrokes.
    autoRepeatInterval = 30;

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

    windowManager.bspwm.enable = true;
  };

  services.udev = {
    extraHwdb = ''
      evdev:input:b0003v1532p026F*
       KEYBOARD_KEY_700e2=leftmeta
       KEYBOARD_KEY_700e3=leftalt
       KEYBOARD_KEY_700e6=rightmeta
    '';
  };

  services.syncthing = {
    enable = true;
    package = unstable.syncthing;
    user = "noib3";
    dataDir = "/home/noib3";
    configDir = "/home/noib3/.config/syncthing";
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}
