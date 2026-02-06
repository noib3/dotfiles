{ lib }:

with lib;
mkOption {
  type = types.submodule (
    { config, ... }:
    {
      options.horizontal = mkOption {
        type = types.submodule {
          options = {
            speed = mkOption {
              type = types.ints.between 1 50;
              description = "Horizontal scroll speed gain control";
              default = 5;
            };
            invertDirection = mkOption {
              type = types.bool;
              description = "Invert horizontal scroll direction";
              default = false;
            };
            scrollSliders = mkOption {
              type = types.bool;
              description = "Scroll over a slider to adjust it";
              default = false;
            };
          };
        };
        default = { };
        description = "Horizontal scroll settings";
      };

      options.vertical = mkOption {
        type = types.submodule {
          options = { };
        };
        default = { };
        description = "Vertical scroll settings";
      };

      # TODO: add options to `scroll.vertical` to configure the remaining parameters.
      options.asBetterMouseFormat = mkOption {
        type = types.attrs;
        internal = true;
        readOnly = true;
        default = {
          acc = [
            32.0
            1.0
          ];
          brake = 4;
          cmdSclGain = 3.162;
          cmdSclMod = 1048576;
          ctrlSclInv = false;
          ctrlSclMod = 262144;
          duration = 12;
          hSclSliderEn = config.horizontal.scrollSliders;
          hSclSliderInv = false;
          horiInvEn = config.horizontal.invertDirection;
          horiSpeed = (config.horizontal.speed) * 1.0;
          lpfDura = 12;
          panelLpf = 0;
          sclThrough = false;
          shiftSclInv = false;
          shiftSclMod = 131072;
          smoothEn = true;
          speed = [
            3
            8
          ];
          vSclSliderEn = false;
          vSclSliderInv = false;
          vertInvEn = false;
        };
      };
    }
  );
  default = { };
  description = "Scroll settings for this app";
}
