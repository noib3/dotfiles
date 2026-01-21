{
  config,
  pkgs,
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
    # Workaround for https://github.com/nix-darwin/nix-darwin/issues/943.
    # nix-darwin doesn't add the XDG profile path to PATH when
    # `use-xdg-base-directories` is enabled.
    environment.profiles = mkOrder 700 [
      "\${XDG_STATE_HOME:-$HOME/.local/state}/nix/profile"
    ];

    environment.systemPackages = with pkgs; [
      home-manager
      neovim
    ];

    modules = {
      brave-policies.enable = true;
      fish.enable = true;
      yabai.enable = true;
    };

    networking = with cfg; {
      computerName = hostName;
      hostName = hostName;
      localHostName = hostName;
    };

    nix = {
      linux-builder.enable = true;

      settings = {
        experimental-features = [
          "flakes"
          "nix-command"
          "pipe-operators"
        ];
        trusted-users = [
          "root"
          cfg.userName
        ];
        use-xdg-base-directories = true;
        warn-dirty = false;
      };
    };

    system = {
      primaryUser = cfg.userName;

      defaults = {
        CustomUserPreferences = {
          "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
          "com.apple.ImageCapture".disableHotPlug = true;
          # Don't create .DS_Store files on network and USB volumes.
          "com.apple.desktopservices" = {
            DSDontWriteNetworkStores = true;
            DSDontWriteUSBStores = true;
          };
        };

        dock = {
          autohide = true;
          # Show the Dock after hovering it for 10 minutes, effectively
          # disabling it.
          autohide-delay = 600.;
          mru-spaces = false;
          persistent-apps = [ ];
          persistent-others = [ ];
          show-recents = false;
          wvous-br-corner = 1;
        };

        finder = {
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
          QuitMenuItem = true;
        };

        LaunchServices.LSQuarantine = false;

        loginwindow = {
          GuestEnabled = false;
          SHOWFULLNAME = true;
        };

        menuExtraClock = {
          Show24Hour = true;
          ShowAMPM = false;
        };

        NSGlobalDomain = {
          AppleICUForce24HourTime = true;
          AppleInterfaceStyle = "Dark";
          AppleKeyboardUIMode = 3;
          AppleMetricUnits = 1;
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
          AppleShowScrollBars = "WhenScrolling";
          InitialKeyRepeat = 10;
          KeyRepeat = 2;
          NSWindowShouldDragOnGesture = true;
        };

        trackpad.Clicking = true;
      };

      keyboard = {
        enableKeyMapping = true;
        remapCapsLockToEscape = true;
      };

      stateVersion = 5;
    };
  };
}
