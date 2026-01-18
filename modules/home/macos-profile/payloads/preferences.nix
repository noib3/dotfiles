{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.macOSPreferences;
  utils = import ../utils.nix { inherit config lib; };

  appType = types.submodule {
    options = {
      forced = mkOption {
        type = types.attrs;
        default = { };
        description = ''
          Preferences that are always enforced. The values are locked and
          cannot be changed by the user or application. Reapplied on every
          login and profile refresh.
        '';
      };

      often = mkOption {
        type = types.attrs;
        default = { };
        description = ''
          Preferences that are applied when the profile is first installed
          and again at each login. User/app changes are allowed during the
          session, but the managed values are restored on the next login.
        '';
      };

      setOnce = mkOption {
        type = types.attrs;
        default = { };
        description = ''
          Preferences that are applied only once when the profile is first
          installed (or when the key doesn't exist). After that, the user
          or application can modify them freely.
        '';
      };
    };
  };
in
{
  options.modules.macOSPreferences = {
    enable = mkEnableOption "macOS configuration profile management";

    apps = mkOption {
      type = types.attrsOf appType;
      default = { };
      description = ''
        App preferences to manage. Keys are bundle IDs (e.g.,
        "com.apple.finder"), values specify settings grouped by management state
        (forced, often, setOnce).
      '';
      example = literalExpression ''
        {
          "com.apple.finder" = {
            forced = {
              ShowPathbar = true;
              ShowStatusBar = true;
            };
            setOnce = {
              NSNavLastRootDirectory = "~/Documents";
            };
          };
          "com.apple.dock" = {
            forced = {
              autohide = true;
              tilesize = 36;
            };
          };
        }
      '';
    };
  }
  // (utils.mkPayloadOptions {
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
      utils.payload2Plist (
        cfg
        // {
          identifier = "${cfg.identifier}.${bundleId}";
          displayName = "${cfg.displayName} (${bundleId})";
          content = {
            "${bundleId}" =
              let
                mkEntry =
                  state: settings:
                  optional (settings != { }) {
                    mcx_preference_settings = settings;
                  };
              in
              filterAttrs (_: v: v != [ ]) {
                Forced = mkEntry "Forced" appSettings.forced;
                Often = mkEntry "Often" appSettings.often;
                Set-Once = mkEntry "Set-Once" appSettings.setOnce;
              };
          };
        }
      )
    ) cfg.apps;
  };
}
