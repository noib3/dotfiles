{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.macOSPreferences;
  inherit (import ../utils.nix { inherit lib; }) mkPayloadOptions payload2Plist;
in
{
  options.modules.macOSPreferences = {
    enable = mkEnableOption "macOS configuration profile management";

    domains = mkOption {
      type = types.attrsOf types.attrs;
      default = { };
      description = ''
        Preference domains to manage. Keys are domain identifiers
        (e.g., "com.apple.finder"), values specify the settings.
      '';
      example = literalExpression ''
        {
          "com.apple.finder" = {
            ShowPathbar = true;
            ShowStatusBar = true;
          };
          "com.apple.dock" = {
            autohide = true;
            tilesize = 36;
          };
        }
      '';
    };
  }
  // (mkPayloadOptions {
    type = "com.apple.ManagedClient.preferences";
    defaultIdentifier = "dev.noib3.NixPreferences";
    defaultDisplayName = "Preferences managed by home-manager";
    contentType = mkOption {
      type = types.attrsOf types.attrs;
      default = { };
      readOnly = true;
    };
  });

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.modules.macOSProfile.enable;
        message = "The macOSPreferences module needs the macOSProfile module";
      }
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "The macOSPreferences module is only available on macOS";
      }
      {
        assertion = cfg.identifier != "";
        message = "The macOSPreferences.identifier key must not be empty";
      }
      {
        assertion = cfg.displayName != "";
        message = "The macOSPreferences.displayName key must not be empty";
      }
    ];

    modules.macOSProfile.content = mapAttrsToList (
      bundleId: appSettings:
      payload2Plist (
        cfg
        // {
          identifier = "${cfg.identifier}.${bundleId}";
          displayName = "${cfg.displayName} (${bundleId})";
          content = {
            "${bundleId}" = {
              # We place all the settings in the `Forced` array to prevent apps
              # from overriding them via the `defaults write` command.
              Forced = [
                {
                  mcx_preference_settings = appSettings;
                }
              ];
            };
          };
        }
      )
    ) cfg.domains;
  };
}
