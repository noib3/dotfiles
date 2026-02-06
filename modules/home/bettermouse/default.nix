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

  # Maps keys to their macOS virtual key code.
  keyCodes = {
    a = 0;
    s = 1;
    d = 2;
    f = 3;
    h = 4;
    g = 5;
    z = 6;
    x = 7;
    c = 8;
    v = 9;
    b = 11;
    q = 12;
    w = 13;
    e = 14;
    r = 15;
    y = 16;
    t = 17;
    "1" = 18;
    "2" = 19;
    "3" = 20;
    "4" = 21;
    "6" = 22;
    "5" = 23;
    equal = 24;
    "9" = 25;
    "7" = 26;
    minus = 27;
    "8" = 28;
    "0" = 29;
    rightBracket = 30;
    o = 31;
    u = 32;
    leftBracket = 33;
    i = 34;
    p = 35;
    return = 36;
    l = 37;
    j = 38;
    quote = 39;
    k = 40;
    semicolon = 41;
    backslash = 42;
    comma = 43;
    slash = 44;
    n = 45;
    m = 46;
    period = 47;
    tab = 48;
    space = 49;
    grave = 50;
    delete = 51;
    escape = 53;
    f5 = 96;
    f6 = 97;
    f7 = 98;
    f3 = 99;
    f8 = 100;
    f9 = 101;
    f11 = 103;
    f10 = 109;
    f12 = 111;
    home = 115;
    pageUp = 116;
    forwardDelete = 117;
    f4 = 118;
    end = 119;
    f2 = 120;
    pageDown = 121;
    f1 = 122;
    left = 123;
    right = 124;
    down = 125;
    up = 126;
  };

  keyType = types.addCheck types.attrs (
    x:
    x ? code
    && builtins.isInt x.code
    && x ? modifiers
    && builtins.isInt x.modifiers
    && x ? plus
    && builtins.isFunction x.plus
  );

  actionType = types.submodule {
    options = {
      actionSel = mkOption {
        type = types.int;
        description = "The action ID used by BetterMouse";
      };
      hotkeyName = mkOption {
        type = types.str;
        default = "";
        description = "Name of the hotkey (if isHotkey is true)";
      };
      isHotkey = mkOption {
        type = types.bool;
        default = false;
        description = "Whether this action sends a hotkey";
      };
      hotkeyMod = mkOption {
        type = types.int;
        default = 0;
        description = "Modifier flags for the hotkey";
      };
      hotkeyKey = mkOption {
        type = types.int;
        default = 0;
        description = "Key code for the hotkey";
      };
      clickTh = mkOption {
        type = types.bool;
        default = false;
        description = "Click threshold";
      };
      clickThEn = mkOption {
        type = types.bool;
        default = false;
        description = "Click threshold enabled";
      };
      multiShot = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to repeat the action while held";
      };
      appName = mkOption {
        type = types.str;
        default = "";
        description = "Application name (for app-specific actions)";
      };
      enabled = mkOption {
        type = types.bool;
        default = true;
        description = "Whether this action is enabled";
      };
    };
  };

  mouseActionKinds = {
    click = 0;
    drag = 1;
    longPress = 2;
    holdAndScroll = 3;
  };

  # Type for a mouse action (click, drag, etc.)
  mouseActionType = types.addCheck types.attrs (
    x: x ? buttonId && builtins.isInt x.buttonId
  );
in
{
  options.modules.bettermouse = {
    enable = mkEnableOption "BetterMouse";

    actions = mkOption {
      type = types.attrsOf actionType;
      description = "Available actions for key and mouse bindings";
      default = {
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
        missionControl = {
          actionSel = 43;
          appName = "Mission Control";
        };
      };
      readOnly = true;
    };

    apps = import ./apps {
      inherit
        lib
        actionType
        keyType
        mouseActionType
        mouseActionKinds
        ;
    };

    autoUpdate = mkOption {
      type = types.bool;
      description = "Whether to automatically check for updates";
      default = false;
    };

    keys = mkOption {
      type = types.attrsOf keyType;
      default =
        let
          mkKey = code: modifiers: {
            inherit code modifiers;
            plus = mod: mkKey code (modifiers + mod);
          };
        in
        mapAttrs (_name: code: mkKey code 0) keyCodes;
      readOnly = true;
    };

    keyModifiers =
      mapAttrs
        (
          name: val:
          mkOption {
            type = types.int;
            description = "${name} modifier";
            default = val;
            readOnly = true;
          }
        )
        {
          shift = 2;
          ctrl = 4;
          option = 8;
          cmd = 16;
        };

    mice = import ./mice { inherit lib mouseActionKinds; };
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
      mice.logitech.MXMaster3SForMac.enable = true;

      apps.global = {
        mouseBindings =
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

        keyBindings = [
          {
            key = cfg.keys.left.plus cfg.keyModifiers.ctrl;
            action = cfg.actions.threeFingerSwipeRightWithKeyboard;
          }
          {
            key = cfg.keys.right.plus cfg.keyModifiers.ctrl;
            action = cfg.actions.threeFingerSwipeLeftWithKeyboard;
          }
        ];
      };
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
