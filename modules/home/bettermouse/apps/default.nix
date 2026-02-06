# Defines the `bettermouse.apps` submodule for per-app settings.

{ lib, cursorCfg }:

with lib;
let
  perAppType = types.submodule (
    { config, ... }:
    {
      options = {
        clickThrough = import ./click-through.nix { inherit lib; };
        keyBindings = import ./key-bindings.nix { inherit lib; };
        mouseBindings = import ./mouse-bindings.nix { inherit lib; };
        pan = import ./pan.nix { inherit lib; };
        scroll = import ./scroll.nix { inherit lib; };

        asBetterMouseFormat = mkOption {
          type = types.attrs;
          internal = true;
          readOnly = true;
          default = {
            btn = config.mouseBindings.asBetterMouseFormat;
            btnLock = config.mouseBindings.lock;
            cursorGain = cursorCfg.gain;
            cursorMod = cursorCfg.mod;
            cursorModifiedRes = cursorCfg.modifiedRes;
            enabled = true;
            key = config.keyBindings.asBetterMouseFormat;
            keyLock = config.keyBindings.lock;
            leftCTEn = config.clickThrough.left;
            # 32 seems to be a sentinel value for "No button pan", which
            # disables panning.
            panBtn = if config.pan.enable then config.pan.button.buttonId else 32;
            panCT = config.clickThrough.pan;
            panInertia = config.pan.inertia;
            panInvert = config.pan.invertDirection;
            # TODO: I don't know what this setting does or how to change its
            # value from any of the UI toggles.
            panMod = 0;
            rightCTEn = config.clickThrough.right;
            scl = config.scroll.asBetterMouseFormat;
            sclEn = config.scroll.enable;
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
                value = appConfig.asBetterMouseFormat // {
                  url =
                    if bundleId == "global" then
                      {
                        relative = "./";
                        base.relative = "file:///";
                      }
                    else
                      throw "Per-app settings for '${bundleId}' are not yet supported: we don't know how to derive the app's URL from its bundle ID";
                };
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
