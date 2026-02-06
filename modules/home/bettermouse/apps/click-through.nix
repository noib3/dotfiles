{ lib }:

with lib;
mkOption {
  type = types.submodule {
    options.left = mkOption {
      type = types.bool;
      description = ''
        When clicking on an inactive window, the click both focuses the
        window and activates the clicked element (instead of just focusing
        the window).
      '';
      default = false;
    };

    options.right = mkOption {
      type = types.bool;
      description = ''
        When right-clicking on an inactive window, the click both focuses
        the window and opens the context menu (instead of just focusing
        the window).
      '';
      default = true;
    };

    options.pan = mkOption {
      type = types.bool;
      description = ''
        When starting a pan gesture on an inactive window, the gesture
        both focuses the window and begins panning.
      '';
      default = true;
    };
  };
  default = { };
  description = "Click-through settings for inactive windows";
}
