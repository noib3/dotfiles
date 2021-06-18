{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> { };

  dirs.defaults = ../../defaults;

  configs = {
    couchdb = (import (dirs.defaults + /couchdb) { inherit lib; });
    transmission = import (dirs.defaults + /transmission);
  };

  falloutGrubTheme = pkgs.fetchgit {
    url = "https://github.com/shvchk/fallout-grub-theme.git";
    rev = "fe27cbc99e994d50bb4269a9388e3f7d60492ffa";
    sha256 = "1z8zc4k2mh8d56ipql8vfljvdjczrrna5ckgzjsdyrndfkwv8ghw";
  };

  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
in
{
  imports = [
    /etc/nixos/hardware-configuration.nix
  ];

  console.keyMap = "us";
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Rome";

  users = {
    users."noib3" = {
      home = "/home/noib3";
      shell = pkgs.fish;
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "input"
        "plugdev"
      ];
    };

    users."couchdb" = {
      home = "/home/couchdb";
      shell = pkgs.fish;
      isSystemUser = true;
      createHome = true;
      extraGroups = [ "couchdb" ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    nvidia-offload
    vim
  ];

  boot = {
    consoleLogLevel = 0;
    kernelParams = [
      "quiet"
      "udev.log_priority=3"
      "button.lid_init_state=open"
      "vt.cur_default=0x700010"
    ];

    initrd.verbose = false;

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

  hardware.nvidia.prime = {
    offload.enable = true;
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
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
  };

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
    videoDrivers = [ "nvidia" ];

    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        disableWhileTyping = true;
      };
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
    # management option. See [1] and [2] for more infos.
    config = ''
      Section "Extensions"
          Option "DPMS" "off"
      EndSection
    '';
  };

  system.stateVersion = "20.09";
}

# [1]: https://wiki.archlinux.org/index.php/Display_Power_Management_Signaling
# [2]: https://shallowsky.com/linux/x-screen-blanking.html
