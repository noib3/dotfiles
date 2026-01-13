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
      profile_exists() {
        /usr/bin/profiles show -identifier "$1" 2>/dev/null | /usr/bin/grep -q "$1"
      }

      # `profiles install` no longer works, and I don't think there's
      # a non-interactive way to install profiles, so we use `open` to open the
      # profile in System Preferences (but only if it's new or changed).

      if profile_exists "${cfg.identifier}"; then
        old_hash="$(/usr/bin/profiles show -identifier "${cfg.identifier}" -output stdout-xml 2>/dev/null \
          | /usr/bin/plutil -convert xml1 -o - - 2>/dev/null \
          | /usr/bin/shasum -a 256 \
          | /usr/bin/awk '{print $1}')"

        new_hash="$(/usr/bin/plutil -convert xml1 -o - "${cfg.generatedProfile}" 2>/dev/null \
          | /usr/bin/shasum -a 256 \
          | /usr/bin/awk '{print $1}')"

        if [ "$new_hash" != "$old_hash" ]; then
          run /usr/bin/open "${cfg.generatedProfile}"
        fi
      else
        run /usr/bin/open "${cfg.generatedProfile}"
      fi
    '';
  };
}
