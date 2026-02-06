# Defines the `bettermouse.keys` submodule.

{ lib }:

with lib;
let
  # Maps keys to their macOS virtual key code.
  keyToCode = {
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

  modifierType = import ./modifier-type.nix { inherit lib; };

  mkKey = code: modifiers: {
    inherit code modifiers;
    plus = modifier: mkKey code (modifiers + modifier.keyBinding);
  };

  keys =
    keyToCode
    |> mapAttrs (
      _name: code:
      mkOption {
        type = import ./key-type.nix { inherit lib; };
        default = mkKey code 0;
        readOnly = true;
      }
    );

  modifiers =
    {
      shift = {
        keyBinding = 2;
        nsEventFlag = 131072; # 0x20000
      };
      ctrl = {
        keyBinding = 4;
        nsEventFlag = 262144; # 0x40000
      };
      option = {
        keyBinding = 8;
        nsEventFlag = 524288; # 0x80000
      };
      cmd = {
        keyBinding = 16;
        nsEventFlag = 1048576; # 0x100000
      };
    }
    |> mapAttrs (
      name: val:
      mkOption {
        type = modifierType;
        description = "${name} modifier";
        default = val;
        readOnly = true;
      }
    );
in
mkOption {
  type = types.submodule {
    options = keys // {
      inherit modifiers;
    };
  };
  default = { };
  description = "Key codes and modifiers for key bindings";
}
