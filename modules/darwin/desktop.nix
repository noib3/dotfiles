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
  imports = [ ./fish.nix ];

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
    modules.fish.userName = cfg.userName;

    networking = with cfg; {
      computerName = hostName;
      hostName = hostName;
      localHostName = hostName;
    };

    services = {
      nix-daemon.enable = true;
    };

    system = {
      defaults = {
        CustomUserPreferences = {
          "com.apple.desktopservices" = {
            # Don't create .DS_Store files on network and USB volumes.
            DSDontWriteNetworkStores = true;
            DSDontWriteUSBStores = true;
          };
          "com.apple.AdLib" = {
            allowApplePersonalizedAdvertising = false;
          };
          "com.apple.ImageCapture".disableHotPlug = true;
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
          NSAutomaticWindowAnimationsEnabled = false;
          NSWindowShouldDragOnGesture = true;
        };

        trackpad.Clicking = true;

        universalaccess.reduceMotion = true;
      };

      keyboard = {
        enableKeyMapping = true;
        remapCapsLockToEscape = true;
      };
    };
  };
}
