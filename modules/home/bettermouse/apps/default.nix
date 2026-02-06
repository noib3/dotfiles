# Defines the `bettermouse.apps` submodule for per-app settings.

{
  lib,
  actionType,
  keyType,
  mouseActionType,
  mouseActionKinds,
}:

with lib;
let
  mouseBindings = import ./mouse-bindings.nix {
    inherit
      lib
      actionType
      mouseActionType
      mouseActionKinds
      ;
  };

  keyBindings = import ./key-bindings.nix { inherit lib actionType keyType; };

  perAppType = types.submodule (
    { config, ... }:
    {
      options = {
        mouseBindings = mouseBindings.option;
        keyBindings = keyBindings.option;
        scroll = import ./scroll.nix { inherit lib; };

        asBetterMouseFormat = mkOption {
          type = types.attrs;
          internal = true;
          readOnly = true;
          default = {
            btn = mouseBindings.toBetterMouseFormat config.mouseBindings;
            key = keyBindings.toBetterMouseFormat config.keyBindings;
            leftCTEn = config.clickThrough.left;
            panCT = config.clickThrough.pan;
            rightCTEn = config.clickThrough.right;
            scl = config.scroll.asBetterMouseFormat;
            # Default settings BetterMouse requires for each app entry.
            enabled = true;
            url = {
              relative = "./";
              base.relative = "file:///";
            };
            panInertia = true;
            panInvert = false;
            panBtn = 1;
            panMod = 0;
            sclEn = true;
            btnLock = false;
            keyLock = false;
            cursorMod = 0;
            cursorGain = 1.0;
            cursorModifiedRes = 26214400;
          };
        };
      };
    }
  );
in
mkOption {
  type = types.submodule (
    { config, ... }:
    {
      freeformType = types.attrsOf perAppType;

      options.asBetterMouseFormat = mkOption {
        type = types.attrs;
        internal = true;
        readOnly = true;
        default = {
          apps =
            config
            |> filterAttrs (name: _: name != "asBetterMouseFormat")
            |> mapAttrs' (
              bundleId: appConfig: {
                name = if bundleId == "global" then "" else bundleId;
                value = appConfig.asBetterMouseFormat;
              }
            );
        };
      };
    }
  );

  description = ''
    Per-app settings. Use "global" for settings that apply to all apps, or a
    bundle ID (e.g. "com.apple.Safari") for app-specific settings.
  '';

  default = {
    global = { };
  };
}
