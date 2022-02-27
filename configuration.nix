{ pkgs
, lib
, config
, username
, homeDirectory
, machine
, colorscheme
, palette
, configDir
, hexlib
, ...
}:

let
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

  # Enable flakes
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs.config.allowUnfree = true;

  console.keyMap = "us";
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Rome";

  users = {
    users."${username}" = {
      home = homeDirectory;
      shell = pkgs.fish;
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "input"
        "networkmanager"
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
    } // (import "${configDir}/grub" {
      inherit pkgs machine colorscheme palette hexlib;
    });

    loader.efi.canTouchEfiVariables = true;
  };

  hardware.bluetooth = {
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

  programs.nm-applet = {
    enable = true;
  };

  services.blueman = {
    enable = true;
  };

  services.couchdb = {
    enable = true;
    package = pkgs.couchdb3;
    user = "couchdb";
    group = "couchdb";
    databaseDir = "/home/couchdb/couchdb";
    bindAddress = "0.0.0.0";
  };

  services.geoclue2 = {
    enable = true;
  };

  services.tlp = {
    enable = true;
  };

  services.transmission = {
    enable = true;
  } // (import "${configDir}/transmission" {
    inherit pkgs username homeDirectory;
  });

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
        user = username;
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

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;
  system.stateVersion = "20.09";
}

# [1]: https://wiki.archlinux.org/index.php/Display_Power_Management_Signaling
# [2]: https://shallowsky.com/linux/x-screen-blanking.html
