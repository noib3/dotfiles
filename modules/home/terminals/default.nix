{ lib, ... }:

let
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
      };
    }
  );
in
{
  options.modules.terminals = lib.mkOption {
    type = lib.types.submodule (
      { config, ... }:
      {
        freeformType = lib.types.attrsOf terminalType;
        options.enabled = lib.mkOption {
          type = lib.types.nullOr terminalType;
          default =
            removeAttrs config [
              "enabled"
              "_module"
            ]
            |> lib.filterAttrs (_: terminal: terminal.enabled)
            |> lib.attrValues
            |> (enabled: if enabled == [ ] then null else builtins.head enabled);
          readOnly = true;
          description = ''
            The first configured terminal with enabled = true, or null if none
            are enabled.
          '';
        };
      }
    );
    default = { };
    description = "Terminal configurations keyed by terminal name.";
  };
}
