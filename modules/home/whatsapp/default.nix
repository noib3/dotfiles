{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.whatsapp;

  package = pkgs.brewCasks.whatsapp.overrideAttrs {
    # The upstream download URL has extension=zip in its query string, but the
    # fixed-output path does not end in .zip. brew-nix then falls through to
    # 7zz, which fails on this archive during the build.
    unpackPhase = ''
      unzip "$src"
    '';
  };
in
{
  options.modules.whatsapp = {
    enable = mkEnableOption "WhatsApp desktop client";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "The WhatsApp desktop client is only available on macOS";
      }
    ];

    home.packages = [
      package
    ];

    modules.macOSPreferences.apps."net.whatsapp.WhatsApp".forced = {
      SUAutomaticallyUpdate = false;
      SUEnableAutomaticChecks = false;
    };
  };
}
