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
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
    colors = [
      "282c34"
      "e06c75"
      "98c379"
      "e5c07b"
      "61afef"
      "c678dd"
      "56b6c2"
      "abb2bf"
      "282c34"
      "be5046"
      "98c379"
      "d19a66"
      "61afef"
      "c678dd"
      "56b6c2"
      "3e4452"
    ];
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    layout = "us";
    libinput = {
      enable = true;
      naturalScrolling = true;
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

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.noib3 = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    home = "/home/noib3";
    shell = pkgs.fish;
  };

  security.sudo = {
    wheelNeedsPassword = false;
  };

  programs.fish = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    evemu
    evtest
    git
    vim
  ];

  services.udev = {
    extraHwdb = ''
      evdev:input:b0003v1532p026F*
       KEYBOARD_KEY_700e2=leftmeta
       KEYBOARD_KEY_700e3=leftalt
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
