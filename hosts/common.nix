# System-wide config shared by every host.

{ lib
, pkgs
, homedir ? "/home/${username}"
, hostname ? "nixos"
, username ? "noib3"
}:

{
  boot = {
    consoleLogLevel = 0;
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

  environment.systemPackages = [
    pkgs.git
    pkgs.neovim
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  hardware.bluetooth = {
    enable = true;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  ];

  networking = {
    hostName = hostname;
    networkmanager.enable = true;
  };

  # programs.nm-applet = {
  #   enable = true;
  # };

  security.sudo.wheelNeedsPassword = false;
  #
  # services.blueman = {
  #   enable = true;
  # };
  #
  # services.geoclue2 = {
  #   enable = true;
  # };
  #
  # services.tlp = {
  #   enable = true;
  # };
  #
  # services.transmission = {
  #   enable = true;
  # } // (import "${configDir}/transmission" {
  #   inherit pkgs username homeDirectory;
  # });
  #
  # services.udisks2 = {
  #   enable = true;
  # };
  #
  # services.udev = {
  #   extraHwdb = ''
  #     evdev:input:b0003v1532p026F*
  #      KEYBOARD_KEY_700e2=leftmeta
  #      KEYBOARD_KEY_700e3=leftalt
  #      KEYBOARD_KEY_700e6=rightmeta
  #   '';
  # };
  #
  # services.xserver = {
  #   enable = true;
  #   autoRepeatDelay = 150;
  #   autoRepeatInterval = 33;
  #   layout = "us";
  #   videoDrivers = [ "nvidia" ];
  #
  #   libinput = {
  #     enable = true;
  #     touchpad = {
  #       naturalScrolling = true;
  #       disableWhileTyping = true;
  #     };
  #   };
  #
  #   displayManager = {
  #     autoLogin = {
  #       enable = true;
  #       user = username;
  #     };
  #   };
  #
  #   windowManager = {
  #     bspwm.enable = true;
  #   };
  #
  #   # This together with 'xset s off'should disable every display power
  #   # management option. See [1] and [2] for more infos.
  #   config = ''
  #     Section "Extensions"
  #         Option "DPMS" "off"
  #     EndSection
  #   '';
  # };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  time.timeZone = "Asia/Singapore";

  users.users."${username}" = {
    home = homeDirectory;
    shell = pkgs.fish;
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
}
