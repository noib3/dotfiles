{ lib }:

with lib;
types.submodule {
  options = {
    actionSel = mkOption {
      type = types.int;
      description = "The action ID used by BetterMouse";
    };
    hotkeyName = mkOption {
      type = types.str;
      default = "";
      description = "Name of the hotkey (if isHotkey is true)";
    };
    isHotkey = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this action sends a hotkey";
    };
    hotkeyMod = mkOption {
      type = types.int;
      default = 0;
      description = "Modifier flags for the hotkey";
    };
    hotkeyKey = mkOption {
      type = types.int;
      default = 0;
      description = "Key code for the hotkey";
    };
    clickTh = mkOption {
      type = types.bool;
      default = false;
      description = "Click threshold";
    };
    clickThEn = mkOption {
      type = types.bool;
      default = false;
      description = "Click threshold enabled";
    };
    multiShot = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to repeat the action while held";
    };
    appName = mkOption {
      type = types.str;
      default = "";
      description = "Application name (for app-specific actions)";
    };
    enabled = mkOption {
      type = types.bool;
      default = true;
      description = "Whether this action is enabled";
    };
  };
}
