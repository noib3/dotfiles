{ config, lib, pkgs, ... }:

let
  unstable = import <nixos-unstable> { };

  colorscheme = "onedark";

  dirs = {
    colorscheme = ../../colorschemes + "/${colorscheme}";
    configs = ../../configs;
  };

  configs = {
    grub = (
      import (dirs.configs + /grub) {
        colors = import (dirs.colorscheme + /grub.nix);
        background-image = dirs.colorscheme + /background.png;
      }
    );

    transmission = import (dirs.configs + /transmission);
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
      splashImage = dirs.colorscheme + /background.png;
      theme = configs.grub;
    };

    loader.efi.canTouchEfiVariables = true;
  };

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

  services.couchdb = {
    enable = true;
    package = unstable.couchdb3;
    user = "couchdb";
    group = "couchdb";
    databaseDir = "/home/couchdb/couchdb";
    bindAddress = "0.0.0.0";
  };

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
