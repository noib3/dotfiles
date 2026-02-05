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
      "com.apple.Spotlight".forced = {
        # Don't show the Spotlight icon in the menu bar.
        MenuItemHidden = 1;
      };
    };
  };
}
