# Defines the `bettermouse.cursor` submodule.

{ lib }:

with lib;
mkOption {
  type = types.submodule (
    { config, ... }:
    {
      options.control = mkOption {
        type = types.submodule (
          { config, ... }:
          {
            options.enable = mkOption {
              type = types.bool;
              description = ''
                Override macOS tracking speed with separate acceleration and
                speed controls. This is the same as "System Settings > Mouse
                > Tracking speed", but with acceleration and speed separated.
                Toggling this off restores the system defaults.
              '';
              default = false;
            };

            options.acceleration = mkOption {
              type = types.int;
              description = "Cursor acceleration";
              default = 68;
            };

            options.speed = mkOption {
              type = types.int;
              description = "Cursor speed";
              default = 5;
            };

            # Maps to optCsr in BetterMouse's config format.
            options.asBetterMouseFormat = mkOption {
              type = types.attrs;
              internal = true;
              readOnly = true;
              default = {
                en = config.enable;
                acc = [
                  config.acceleration
                  config.acceleration
                ];
                res = [
                  config.speed
                  config.speed
                ];
              };
            };
          }
        );
        default = { };
        description = "Cursor control settings (acceleration and speed)";
      };

      options.holdInGesture = mkOption {
        type = types.bool;
        description = "Whether to hold the cursor in place during gestures";
        default = false;
      };

      options.speedModifier = mkOption {
        type = types.submodule {
          options.enable = mkOption {
            type = types.bool;
            description = "Whether cursor speed modification is enabled";
            default = false;
          };

          options.modifier = mkOption {
            type = import ../keys/modifier-type.nix { inherit lib; };
            description = "Modifier key that activates the cursor speed change";
          };

          options.gain = mkOption {
            type = types.float;
            description = ''
              Cursor speed gain when the modifier key is held. For example,
              a gain of 4 means 4x faster, a gain of 1/5 means 5x slower.
            '';
            default = 1.0;
          };
        };
        default = { };
        description = "Hold a modifier key to temporarily change cursor speed";
      };

      # Despite the name, this is actually 1/gain: BetterMouse's cursorGain
      # field is the inverse of the UI's speed multiplier.
      options.gain = mkOption {
        type = types.float;
        internal = true;
        readOnly = true;
        default =
          if config.speedModifier.enable then 1.0 / config.speedModifier.gain else 1.0;
      };

      # Maps to cursorMod in BetterMouse's per-app format. Uses macOS
      # NSEventModifierFlags encoding. 0 when disabled.
      options.mod = mkOption {
        type = types.int;
        internal = true;
        readOnly = true;
        default =
          if config.speedModifier.enable then
            config.speedModifier.modifier.nsEventFlag
          else
            0;
      };

      # Maps to cursorModifiedRes in BetterMouse's per-app format. It seem to
      # always be 26214400 * gain (the base resolution scaled by gain).
      options.modifiedRes = mkOption {
        type = types.int;
        internal = true;
        readOnly = true;
        default = builtins.floor (26214400 * config.gain);
      };
    }
  );
  default = { };
  description = "Cursor settings";
}
