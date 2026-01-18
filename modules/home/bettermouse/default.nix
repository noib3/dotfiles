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
  # config = {
  #   cursorHold = false;
  #   hideIcon = true;
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

  mouseActionKinds = {
    click = 0;
    drag = 1;
    longPress = 2;
    holdAndScroll = 3;
  };

  # Creates a mouse button definition with click, drag, longPress, and
  # holdAndScroll actions.
  #
  # Input:  { buttonId = 5; }
  # Output: {
  #   buttonId = 5;
  #   click = { buttonId = 5; clickSubtype = 2; };
  #   drag = { direction }: { buttonId = 5; direction = ...; };
  #   longPress = { ... }: { ... };  # TODO
  #   holdAndScroll = { ... }: { ... };  # TODO
  # }
  mkMouseButton =
    { buttonId }:
    {
      inherit buttonId;

      click = {
        kind = mouseActionKinds.click;
        inherit buttonId;
        # TODO: discover other click subtypes (double click, etc.)
        clickSubtype = 2; # single click
      };

      drag =
        { direction }:
        {
          kind = mouseActionKinds.drag;
          inherit buttonId;
          direction = requireDirection {
            up = 0;
            left = 1;
            down = 2;
            right = 3;
          } direction;
        };

      # TODO: implement once we have examples of the schema.
      longPress =
        {
          triggerDelayMillisecs,
          repeatIntervalMillisecs,
        }:
        {
          kind = mouseActionKinds.longPress;
          inherit buttonId;
          inherit triggerDelayMillisecs repeatIntervalMillisecs;
        };

      # TODO: implement once we have examples of the schema.
      holdAndScroll =
        { direction }:
        {
          kind = mouseActionKinds.holdAndScroll;
          inherit buttonId;
          direction = requireDirection {
            up = 0;
            down = 2;
          } direction;
        };
    };

  # Type for a mouse action (click, drag, etc.)
  mouseActionType = types.addCheck types.attrs (
    x: x ? buttonId && builtins.isInt x.buttonId
  );

  # Convert a list of mouse bindings to BetterMouse's btn array format.
  # Bindings are grouped by button ID, then by modifier, then by gesture type.
  #
  # Input:  [ { mouseAction = { buttonId = 5; clickSubtype = 2; };
  #             targetAction = { actionSel = 43; ... }; }
  #           { mouseAction = { buttonId = 2; direction = 1; };
  #             targetAction = { actionSel = 22; ... }; } ]
  #
  # Output: [ 5 [ 0 [ { Click = {}; } [ 2 <action> ] ] ]
  #           2 [ 0 [ { Move = {}; } [ 1 <action> ] ] ] ]
  bindingsToButtonArray =
    let
      # Convert bindings for a single button
      mkButtonConfig =
        buttonBindings:
        let
          # Convert click bindings: [clickSubtype, action, ...]
          clickActions =
            buttonBindings
            |> filter (binding: binding.mouseAction.kind == mouseActionKinds.click)
            |> map (binding: [
              binding.mouseAction.clickSubtype
              binding.targetAction
            ])
            |> concatLists;

          # Convert drag bindings: [direction, action, ...]
          dragActions =
            buttonBindings
            |> filter (binding: binding.mouseAction.kind == mouseActionKinds.drag)
            |> map (binding: [
              binding.mouseAction.direction
              binding.targetAction
            ])
            |> concatLists;

          gestureConfigs =
            (optional (clickActions != [ ]) [
              { Click = { }; }
              clickActions
            ])
            ++ (optional (dragActions != [ ]) [
              { Move = { }; }
              dragActions
            ]);
        in
        # BetterMouse expects [modifier, gestureConfig] pairs. For now, all
        # bindings use modifier 0 (no modifier).
        gestureConfigs
        |> map (gestureConfig: [
          0
          gestureConfig
        ])
        |> concatLists;
    in
    bindings:
    groupBy (binding: toString binding.mouseAction.buttonId) bindings
    |> mapAttrsToList (
      buttonIdStr: buttonBindings: [
        (toInt buttonIdStr)
        (mkButtonConfig buttonBindings)
      ]
    )
    |> concatLists;

  # Convert a list of key bindings to BetterMouse's key array format.
  # Bindings with the same base key code are merged together.
  #
  # Input:  [ { key = { code = 124; modifiers = 4; }; action = ...; }
  #           { key = { code = 124; modifiers = 8; }; action = ...; }
  #           { key = { code = 123; modifiers = 4; }; action = ...; } ]
  #
  # Output: [ 124 [ 4 <action> 8 <action> ]
  #           123 [ 4 <action> ] ]
  bindingsToKeyArray =
    bindings:
    groupBy (binding: toString binding.key.code) bindings
    |> mapAttrsToList (
      codeStr: bindings: [
        (toInt codeStr)
        (
          bindings
          |> map (binding: [
            binding.key.modifiers
            binding.action
          ])
          |> concatLists
        )
      ]
    )
    |> concatLists;

  # Default settings for each app entry in appitems.apps.
  # BetterMouse requires all these fields to be present.
  appDefaults = {
    enabled = true;
    url = {
      relative = "./";
      base.relative = "file:///";
    };
    leftCTEn = false;
    rightCTEn = true;
    panInertia = true;
    panInvert = false;
    panCT = true;
    panBtn = 1;
    panMod = 0;
    sclEn = true;
    btnLock = false;
    keyLock = false;
    cursorMod = 0;
    cursorGain = 1.0;
    cursorModifiedRes = 26214400;
  };
in
{
  options.modules.bettermouse = {
    enable = mkEnableOption "BetterMouse";

    autoUpdate = mkOption {
      type = types.bool;
      description = "Whether to automatically check for updates";
      default = false;
    };

    keyBindings = mkOption {
      type =
        let
          keyBindingType = types.submodule {
            options = {
              key = mkOption {
                type = keyType;
                description = "The key (with optional modifiers) that triggers this binding";
              };
              action = mkOption {
                type = actionType;
                description = "The action to perform when the key is pressed";
              };
            };
          };
        in
        types.attrsOf (types.listOf keyBindingType);
      description = ''
        Key bindings per application. Use "global" for bindings that apply to
        all apps, or a bundle ID (e.g. "com.apple.Safari") for app-specific
        bindings.
      '';
      example = literalExpression ''
        {
          global = [
            {
              key = cfg.keys.right.plus cfg.keyModifiers.ctrl;
              action = cfg.actions.threeFingerSwipeRight;
            }
          ];
          "com.apple.Safari" = [
            {
              key = cfg.keys.left.plus cfg.keyModifiers.cmd;
              action = cfg.actions.back;
            }
          ];
        }
      '';
      default = { };
    };

    mouseBindings = mkOption {
      type =
        let
          mouseBindingType = types.submodule {
            options = {
              mouseAction = mkOption {
                type = mouseActionType;
                description = "The mouse action (click, drag, etc.) that triggers this binding";
              };
              targetAction = mkOption {
                type = actionType;
                description = "The action to perform when the mouse action occurs";
              };
            };
          };
        in
        types.attrsOf (types.listOf mouseBindingType);
      description = ''
        Mouse button bindings per application. Use "global" for bindings that
        apply to all apps, or a bundle ID for app-specific bindings.
      '';
      example = literalExpression ''
        {
          global =
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
                targetAction = cfg.actions.threeFingerSwipeLeft;
              }
            ];
        }
      '';
      default = { };
    };

    scroll = import ./scroll.nix { inherit lib; };

    mice = mkOption {
      type = types.attrs;
      description = "Available mouse definitions by vendor and model";
      default = {
        logitech = {
          MXMaster3SForMac = {
            buttons = {
              wheel = mkMouseButton { buttonId = 2; };
              thumb = mkMouseButton { buttonId = 5; };
              # TODO: add other buttons as we discover their IDs
            };
          };
        };
      };
      readOnly = true;
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
      mouseBindings.global =
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

      keyBindings.global = [
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

    modules.macOSPreferences.apps."com.naotanhaocan.BetterMouse" = {
      forced = {
        SUEnableAutomaticChecks = if cfg.autoUpdate then 1 else 0;

        appitems = mkBetterMouseConfig {
          apps =
            # Collect all bundle IDs that have any settings defined.
            (lib.attrNames cfg.keyBindings)
            ++ (lib.attrNames cfg.mouseBindings)
            ++ (lib.attrNames cfg.scroll)
            # Remove duplicates.
            |> lib.unique
            |> map (bundleId: {
              name = if bundleId == "global" then "" else bundleId;
              value = appDefaults // {
                key = bindingsToKeyArray (cfg.keyBindings.${bundleId} or [ ]);
                btn = bindingsToButtonArray (cfg.mouseBindings.${bundleId} or [ ]);
                scl = lib.attrsets.optionalAttrs (
                  cfg.scroll ? ${bundleId}
                ) cfg.scroll.${bundleId}.asBetterMouseFormat;
              };
            })
            |> lib.listToAttrs;
        };
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
