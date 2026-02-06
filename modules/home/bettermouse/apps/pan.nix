{ lib }:

with lib;
let
  mouseButtonType = import ../mice/button-type.nix { inherit lib; };
in
mkOption {
  type = types.submodule {
    options.enable = mkOption {
      type = types.bool;
      description = "Whether panning (drag-to-scroll) is enabled";
      default = true;
    };

    options.button = mkOption {
      type = mouseButtonType;
      description = ''
        Mouse button used for panning. Drag gestures assigned to this button
        will be overridden by the pan function.
      '';
    };

    options.inertia = mkOption {
      type = types.bool;
      description = "Trackpad-style inertia for the right button pan";
      default = true;
    };

    options.invertDirection = mkOption {
      type = types.bool;
      description = "Invert the pan direction";
      default = false;
    };
  };
  default = { };
  description = "Pan (drag-to-scroll) settings";
}
