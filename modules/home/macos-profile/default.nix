{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.macOSProfile;
  inherit (import ./utils.nix { inherit lib; }) mkPayloadOptions payload2Plist;
in
{
  imports = [ ./payloads ];

  options.modules.macOSProfile = {
    enable = mkEnableOption "macOS configuration profile management";

    generatedProfile = mkOption {
      type = types.path;
      description = "Path to the generated .mobileconfig profile file";
      readOnly = true;
      default = pkgs.writeText "${cfg.identifier}.mobileconfig" (
        generators.toPlist { escape = true; } (payload2Plist cfg)
      );
    };
  }
  // (mkPayloadOptions {
    type = "Configuration";
    defaultIdentifier = "dev.noib3.NixProfile";
    defaultDisplayName = "Profile managed by Home-manager";
    contentType = mkOption {
      type = types.listOf types.attrs;
      description = "List of payloads to include in the profile";
      default = [ ];
    };
  });

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "The macOSProfile module is only available on macOS";
      }
      {
        assertion = cfg.identifier != "";
        message = "The macOSProfile.identifier key must not be empty";
      }
      {
        assertion = cfg.displayName != "";
        message = "The macOSProfile.displayName key must not be empty";
      }
    ];

    home.activation.setMacOSProfile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      install_macos_profile() {
        PROFILE_ID="${cfg.identifier}"
        PROFILE_PATH="${cfg.generatedProfile}"
        STATE_DIR="${config.xdg.stateHome}/macos-profile"
        CURRENT_PROFILE="$STATE_DIR/current.mobileconfig"

        # Return early if the profile hasn't changed.
        if [[ -L "$CURRENT_PROFILE" ]] && /usr/bin/cmp -s "$CURRENT_PROFILE" "$PROFILE_PATH"; then
          return 0
        fi

        # Update the current profile and open System Settings to let the user
        # install it (unfortunately `profiles install` no longer works, and
        # I don't think there's another non-interactive way of installing
        # profiles).
        run mkdir -p "$STATE_DIR"
        run ln -sfn "$PROFILE_PATH" "$CURRENT_PROFILE"
        run /usr/bin/open "$PROFILE_PATH"
        run /usr/bin/open "x-apple.systempreferences:com.apple.Profiles-Settings.extension"
      }

      install_macos_profile
    '';
  };
}
