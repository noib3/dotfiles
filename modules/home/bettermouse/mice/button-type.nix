{ lib }:

let
  inherit (lib) mkOption types;

  # Helper to validate a direction against allowed values and return it.
  requireDirection =
    allowed: direction:
    let
      validOptions = builtins.concatStringsSep ", " (builtins.attrNames allowed);
    in
    if allowed ? ${direction} then
      allowed.${direction}
    else
      throw "Invalid direction '${direction}'. Must be one of: ${validOptions}";

  mouseActionKinds = import ./action-kinds.nix;
in
types.submodule (
  { config, ... }:
  {
    options = {
      buttonId = mkOption {
        type = types.int;
        description = "The button ID used by BetterMouse";
      };

      click = mkOption {
        type = types.attrs;
        description = "Click action for this button";
        default = {
          kind = mouseActionKinds.click;
          buttonId = config.buttonId;
          # TODO: discover other click subtypes (double click, etc.)
          clickSubtype = 2; # single click
        };
        readOnly = true;
      };

      drag = mkOption {
        type = types.functionTo types.attrs;
        description = "Function to create a drag action: { direction } -> action";
        default =
          { direction }:
          {
            kind = mouseActionKinds.drag;
            buttonId = config.buttonId;
            direction = requireDirection {
              up = 0;
              left = 1;
              down = 2;
              right = 3;
            } direction;
          };
        readOnly = true;
      };

      longPress = mkOption {
        type = types.functionTo types.attrs;
        description = "Function to create a long press action: { triggerDelayMillisecs, repeatIntervalMillisecs } -> action";
        default =
          {
            triggerDelayMillisecs,
            repeatIntervalMillisecs,
          }:
          {
            kind = mouseActionKinds.longPress;
            buttonId = config.buttonId;
            inherit triggerDelayMillisecs repeatIntervalMillisecs;
          };
        readOnly = true;
      };

      holdAndScroll = mkOption {
        type = types.functionTo types.attrs;
        description = "Function to create a hold-and-scroll action: { direction } -> action";
        default =
          { direction }:
          {
            kind = mouseActionKinds.holdAndScroll;
            buttonId = config.buttonId;
            direction = requireDirection {
              up = 0;
              down = 2;
            } direction;
          };
        readOnly = true;
      };
    };
  }
)
