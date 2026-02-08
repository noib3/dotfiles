{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.macosDefaults;
in
{
  options.modules.macosDefaults = {
    enable = mkEnableOption "macOS system defaults";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "The macosDefaults module is only available on macOS";
      }
    ];

    modules.macOSPreferences.apps = {
      ".GlobalPreferences".forced = {
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
      "com.apple.AdLib".forced = {
        allowApplePersonalizedAdvertising = false;
      };
      "com.apple.AppleMultitouchTrackpad".forced = {
        Clicking = true;
      };
      "com.apple.controlcenter".forced = {
        # Show the Bluetooth icon in the menu bar. Not sure what 18 means, but
        # 0 hides it and 18 shows it. See https://roundfleet.com/tutorial/2025-07-07-bluetooth-menu-status-bar-macos
        # for more infos.
        Bluetooth = 18;
        # Don't show the "Now Playing" icon in the menu bar. Again, not sure
        # what 8 means. I found this value by checking the output of
        # `defaults -currentHost read com.apple.controlcenter` before/after
        # hiding it manually via System Settings > Control Center > Now Playing.
        NowPlaying = 8;
      };
      # Don't create .DS_Store files on network and USB volumes.
      "com.apple.desktopservices".forced = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.dock".forced = {
        autohide = true;
        # Show the Dock after hovering it for 10 minutes, effectively disabling
        # it.
        autohide-delay = 600.0;
        mru-spaces = false;
        persistent-apps = [ ];
        persistent-others = [ ];
        show-recents = false;
        wvous-br-corner = 1;
      };
      "com.apple.driver.AppleBluetoothMultitouch.trackpad".forced = {
        Clicking = true;
      };
      "com.apple.finder".forced = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        QuitMenuItem = true;
      };
      "com.apple.ImageCapture".forced = {
        disableHotPlug = true;
      };
      "com.apple.LaunchServices".forced = {
        LSQuarantine = false;
      };
      "com.apple.loginwindow".forced = {
        GuestEnabled = false;
        SHOWFULLNAME = true;
      };
      "com.apple.menuextra.clock".forced = {
        Show24Hour = true;
        ShowAMPM = false;
      };
      "com.apple.screencapture".forced = {
        show-thumbnail = true;
      };
      "com.apple.Spotlight".forced = {
        # Don't show the Spotlight icon in the menu bar.
        MenuItemHidden = 1;
      };
    };
  };
}
