{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.defaults;

  valueType =
    with lib.types;
    nullOr (oneOf [
      bool
      int
      float
      str
      path
      (attrsOf valueType)
      (listOf valueType)
    ])
    // {
      description = "plist value";
    };

  # Generate a defaults write command for a single key-value pair.
  writeDefault =
    domain: key: value:
    let
      plistValue = generators.toPlist { escape = true; } value;
      # Escape single quotes for shell.
      escapedPlist = strings.escape [ "'" ] plistValue;
    in
    "$DRY_RUN_CMD /usr/bin/defaults write ${domain} '${key}' $'${escapedPlist}'";

  defaultsToList =
    domain: attrs: mapAttrsToList (writeDefault domain) (filterAttrs (n: v: v != null) attrs);

  customUserPreferencesCommands = concatStringsSep "\n" (
    flatten (mapAttrsToList defaultsToList cfg.CustomUserPreferences)
  );
in
{
  options = {
    modules.defaults.CustomUserPreferences = mkOption {
      type = types.attrsOf (
        types.submodule {
          freeformType = valueType;
        }
      );
      default = { };
      description = ''
        Set custom user preferences via macOS's defaults system.

        This is equivalent to running `defaults write` commands for each
        preference specified. The outer attribute set keys are domain names,
        and the values are attribute sets of preference keys and values.
      '';
    };
  };

  config = mkIf (cfg.CustomUserPreferences != { }) {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "The defaults module is only available on macOS";
      }
    ];

    home.activation.setMacosDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${customUserPreferencesCommands}
    '';
  };
}
