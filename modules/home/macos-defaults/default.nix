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
      "com.apple.Spotlight".forced = {
        # Don't show the Spotlight icon in the menu bar.
        MenuItemHidden = 1;
      };
    };
  };
}
