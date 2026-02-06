# Defines the `bettermouse.apps` submodule for per-app settings.

{ lib }:

with lib;
let
  mouseBindings = import ./mouse-bindings.nix { inherit lib; };

  keyBindings = import ./key-bindings.nix { inherit lib; };

  perAppType = types.submodule (
    { config, ... }:
    {
      options = {
        clickThrough = import ./click-through.nix { inherit lib; };
        keyBindings = keyBindings.option;
        mouseBindings = mouseBindings.option;
        pan = import ./pan.nix { inherit lib; };
        scroll = import ./scroll.nix { inherit lib; };

        asBetterMouseFormat = mkOption {
          type = types.attrs;
          internal = true;
          readOnly = true;
          default = {
            btn = mouseBindings.toBetterMouseFormat config.mouseBindings;
            key = keyBindings.toBetterMouseFormat config.keyBindings;
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
            # Default settings BetterMouse requires for each app entry.
            enabled = true;
            url = {
              relative = "./";
              base.relative = "file:///";
            };
            btnLock = false;
            cursorGain = 1.0;
            cursorMod = 0;
            cursorModifiedRes = 26214400;
            keyLock = false;
            sclEn = true;
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
