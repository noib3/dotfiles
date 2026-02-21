{ config, lib, ... }:

let
  cfg = config.modules.terminals;

  terminalType = lib.types.submodule (
    { config, ... }:
    {
      options = {
        enabled = lib.mkEnableOption "this terminal";
        package = lib.mkOption {
          type = lib.types.package;
          description = "The package of the configured terminal";
        };
        launchCommand = lib.mkOption {
          type = lib.types.str;
          description = "The command used to open a new terminal window";
          default = lib.getExe config.package;
        };
        terminfo = lib.mkOption {
          type = lib.types.attrsOf lib.types.package;
          default = { };
          description = ''
            Terminfo sources keyed by terminfo database name. Each value should
            evaluate to a directory containing one or more terminfo directories.
          '';
        };
      };
    }
  );

  enabledTerminals =
    removeAttrs cfg [
      "enabled"
      "_module"
    ]
    |> lib.filterAttrs (_: terminal: terminal.enabled or false)
    |> lib.attrValues;
in
{
  options.modules.terminals = lib.mkOption {
    type = lib.types.submodule {
      freeformType = lib.types.attrsOf terminalType;
      options.enabled = lib.mkOption {
        type = lib.types.nullOr terminalType;
        default =
          if enabledTerminals == [ ] then null else builtins.head enabledTerminals;
        readOnly = true;
        description = ''
          The first configured terminal with enabled = true, or null if none
          are enabled
        '';
      };
    };
    default = { };
    description = "Terminal configurations keyed by terminal name";
  };

  config.assertions = [
    {
      assertion = builtins.length enabledTerminals <= 1;
      message = "modules.terminals can have at most one enabled entry";
    }
  ];
}
