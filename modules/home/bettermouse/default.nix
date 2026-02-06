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
    apps = import ./apps {
      inherit lib;
      cursorCfg = cfg.cursor;
    };
    autoUpdate = mkOption {
      type = types.bool;
      description = "Whether to automatically check for updates";
      default = false;
    };
    cursor = import ./cursor { inherit lib; };
    hideIcon = mkOption {
      type = types.bool;
      description = ''
        Whether to hide BetterMouse's menu bar icon. To make the icon
        reappear, launch the app again while it's already running.
      '';
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

      cursor = {
        control.enable = true;
        holdInGesture = true;
      };

      hideIcon = true;

      mice.logitech.MXMaster3SForMac.enable = true;
    };

    modules.macOSPreferences.apps."com.naotanhaocan.BetterMouse" = {
      forced = {
        appitems = mkBetterMouseConfig cfg.apps.asBetterMouseFormat;
        mice = mkBetterMouseConfig cfg.mice.asBetterMouseFormat;
        SUEnableAutomaticChecks = if cfg.autoUpdate then 1 else 0;
      };

      # For `config`, we have to use `often` instead of `forced` because
      # BetterMouse uses it to persist some internal state.
      often = {
        config = mkBetterMouseConfig {
          cursorHold = if cfg.cursor.holdInGesture then 1 else 0;
          hideIcon = if cfg.hideIcon then 1 else 0;
          optCsr = cfg.cursor.control.asBetterMouseFormat;
        };
      };
    };

    launchd.agents.bettermouse-reset-trial =
      let
        resetTrial = pkgs.writeShellApplication {
          name = "bettermouse-reset-trial";
          text = builtins.readFile ./reset-trial.sh;
        };
      in
      {
        enable = true;
        config = {
          ProgramArguments = [ (lib.getExe resetTrial) ];
          StartCalendarInterval = [
            # Runs every day at 4:00 AM.
            {
              Hour = 4;
              Minute = 0;
            }
          ];
        };
      };
  };
}
