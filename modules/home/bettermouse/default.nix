{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.bettermouse;
  toPlist = value: lib.generators.toPlist { escape = true; } value;
  utils = import ../macos-profile/utils.nix { inherit config lib; };

  # As of version 1.6.8589, the BetterMouse config schema has the following
  # top-level keys:
  #
  # - `appitems`: per-app settings keyed by bundle ID;
  # - `config`: BetterMouse's own UI/general behavior settings;
  # - `ee`: …not sure;
  # - `keyboards`: keyboard key remapping configurations;
  # - `logikeys`: Logitech-specific keyboard features;
  # - `mice`: mouse-specific configs;
  # - `ver`: version string as raw bytes;
  #
  # with the exception of `ver`, all the other keys have values that are
  # themselves plists, base64-encoded and stored in `<data>` tags. The
  # plist-in-plist approach is an app-level choice: BetterMouse could've
  # serialized the data using any other format like JSON, protobuf, etc. They
  # chose plists.
  #
  # This means that to convert the following example `config`:
  #
  # ```nix
  # {
  #   config = {
  #     cursorHold = false;
  #     hideIcon = true;
  #   };
  # }
  # ```
  #
  # into the format expected by BetterMouse, we have to:
  #
  # 1) take the `config` attrset;
  # 2) convert it into a plist string;
  # 3) base64 encode the plist string;
  # 4) annotate the base64-encoded string in such a way that our nix-to-plist
  #    converter recognizes it's supposed to be a binary blob and wraps it in
  #    `<data/>` tags when it generates the final plist artifact.
  #
  # Steps 3) and 4) are handled by `mkPlistData`, and the following function
  # puts it all together.
  mkBetterMouseConfig = attrs: utils.mkPlistData (toPlist attrs);
in
{
  options.modules.bettermouse = {
    enable = mkEnableOption "BetterMouse";
    actions = import ./actions { inherit lib; };
    apps = import ./apps { inherit lib; };
    autoUpdate = mkOption {
      type = types.bool;
      description = "Whether to automatically check for updates";
      default = false;
    };
    keys = import ./keys { inherit lib; };
    mice = import ./mice { inherit lib; };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "BetterMouse is only available on macOS";
      }
    ];

    home.packages = [
      pkgs.brewCasks.bettermouse
    ];

    modules.bettermouse = {
      apps.global = {
        keyBindings.bindings = [
          {
            key = cfg.keys.left.plus cfg.keys.modifiers.ctrl;
            action = cfg.actions.threeFingerSwipeRightWithKeyboard;
          }
          {
            key = cfg.keys.right.plus cfg.keys.modifiers.ctrl;
            action = cfg.actions.threeFingerSwipeLeftWithKeyboard;
          }
        ];

        mouseBindings.bindings =
          let
            inherit (cfg.mice.logitech.MXMaster3SForMac) buttons;
          in
          [
            {
              mouseAction = buttons.thumb.click;
              targetAction = cfg.actions.missionControl;
            }
            {
              mouseAction = buttons.wheel.drag { direction = "left"; };
              targetAction = cfg.actions.threeFingerSwipeLeftWithMouse;
            }
            {
              mouseAction = buttons.wheel.drag { direction = "right"; };
              targetAction = cfg.actions.threeFingerSwipeRightWithMouse;
            }
          ];

        pan.enable = false;
      };

      mice.logitech.MXMaster3SForMac.enable = true;
    };

    modules.macOSPreferences.apps."com.naotanhaocan.BetterMouse" = {
      forced = {
        appitems = mkBetterMouseConfig cfg.apps.asBetterMouseFormat;
        mice = mkBetterMouseConfig cfg.mice.asBetterMouseFormat;
        SUEnableAutomaticChecks = if cfg.autoUpdate then 1 else 0;
      };

      # For `config`, we use `often` instead of `forced` because when it's
      # forced, keyboard bindings aren't applied until the "Keyboard" pane in
      # the UI is manually focused once.
      #
      # My best guess is that BetterMouse needs to write some internal state to
      # `config` during startup, and when it can't (because the preference is
      # locked), it skips initialization of other systems like keyboard
      # bindings.
      often = {
        config = mkBetterMouseConfig {
          cursorHold = false;
          hideIcon = false;
          leftDragLimit = true;
          leftDragLimitRange = 10.0;
          longPressPeriod = 0.5;
          longPressRepeatInterval = 0.1;
          registered = 0.0;
          showDescription = true;
          tabSelection = 5;
          trialLeft = 7.0;
          optCsr = {
            en = false;
            acc = [
              68.75
              68.75
            ];
            res = [
              5.0
              5.0
            ];
          };
        };
      };
    };
  };
}
