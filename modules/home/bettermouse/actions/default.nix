# Defines the `bettermouse.actions` submodule.

{ lib }:

with lib;
mkOption {
  type = types.attrsOf (import ./action-type.nix { inherit lib; });
  description = "Available actions for key and mouse bindings";
  default = {
    missionControl = {
      actionSel = 43;
      appName = "Mission Control";
    };
    # The 3-finger-swipe actions use different selectors depending on
    # whether the action is meant to be performed with a mouse or with
    # a keyboard. AFAICT, the only difference is that the mouse swipes are
    # proportional (the space transition tracks the mouse movement), while
    # the keyboard swipes are discrete (the space switch happens immediately
    # when the binding is triggered). Also, from my testing the keyboard
    # swipes can be used as mouse actions, but the mouse swipes can't be
    # used as keyboard actions.
    threeFingerSwipeLeftWithMouse.actionSel = 7;
    threeFingerSwipeRightWithMouse.actionSel = 8;
    threeFingerSwipeLeftWithKeyboard.actionSel = 22;
    threeFingerSwipeRightWithKeyboard.actionSel = 23;
  };
  readOnly = true;
}
