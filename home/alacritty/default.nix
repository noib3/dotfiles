{ font-family
, machine
, palette
, shell
, optionals
, optionalAttrs
, isDarwin
, isLinux
}:

let
  colors = import ./colors.nix { inherit palette; };
  font = import ./font.nix { family = font-family; inherit machine; };
in
{
  settings = {
    inherit shell font colors;

    window = optionalAttrs (machine == "blade")
      {
        padding = {
          x = 3;
          y = 0;
        };
      } // optionalAttrs (machine == "skunk")
      {
        padding = {
          x = 10;
          y = 5;
        };
      } // optionalAttrs (isDarwin) {
      decorations = "buttonless";
    };

    cursor.style = "Beam";

    keyboard.bindings = [
      {
        key = "D";
        mods = "Super";
        chars = "\\u0018\\u0004"; # C-x C-d
      }
      {
        key = "E";
        mods = "Super";
        chars = "\\u0018\\u0005"; # C-x C-e
      }
      {
        key = "H";
        mods = "Super";
        chars = "\\u0018\\u0006"; # C-x C-f
      }
      {
        key = "R";
        mods = "Super";
        chars = "\\u0018\\u0012"; # C-x C-r
      }
      {
        key = "K";
        mods = "Super";
        chars = "\\u0018\\u0007"; # C-x C-g
      }
      {
        key = "L";
        mods = "Super";
        chars = "\\u0007"; # C-g
      }
      {
        key = "S";
        mods = "Super";
        chars = "\\u0013"; # C-s
      }
      {
        key = "T";
        mods = "Super";
        chars = "\\u0014"; # C-t
      }
      {
        key = "W";
        mods = "Super";
        chars = "\\u0017"; # C-w
      }
      {
        key = "Up";
        mods = "Super";
        chars = "\\u0015"; # C-u
      }
      {
        key = "Down";
        mods = "Super";
        chars = "\\u0004"; # C-d
      }
      {
        key = "Left";
        mods = "Super";
        chars = "\\u0001"; # C-a
      }
      {
        key = "Right";
        mods = "Super";
        chars = "\\u0005"; # C-e
      }
      {
        key = "Back";
        mods = "Super";
        chars = "\\u0015"; # C-u
      }
      {
        key = "Key1";
        mods = "Super";
        chars = "\\u001b\\u004f\\u0050"; # F1
      }
      {
        key = "Key2";
        mods = "Super";
        chars = "\\u001b\\u004f\\u0051"; # F2
      }
      {
        key = "Key3";
        mods = "Super";
        chars = "\\u001b\\u004f\\u0052"; # F3
      }
      {
        key = "Key4";
        mods = "Super";
        chars = "\\u001b\\u004f\\u0053"; # F4
      }
      {
        key = "Key5";
        mods = "Super";
        chars = "\\u001b\\u005b\\u0031\\u0035\\u007e"; # F5
      }
      {
        key = "Key6";
        mods = "Super";
        chars = "\\u001b\\u005b\\u0031\\u0037\\u007e"; # F6
      }
      {
        key = "Key7";
        mods = "Super";
        chars = "\\u001b\\u005b\\u0031\\u0038\\u007e"; # F7
      }
      {
        key = "Key8";
        mods = "Super";
        chars = "\\u001b\\u005b\\u0031\\u0039\\u007e"; # F8
      }
      {
        key = "Key9";
        mods = "Super";
        chars = "\\u001b\\u005b\\u0032\\u0030\\u007e"; # F9
      }
    ] ++ optionals isLinux [
      {
        key = "C";
        mods = "Super";
        action = "Copy";
      }
      {
        key = "V";
        mods = "Super";
        action = "Paste";
      }
    ] ++ optionals (machine == "mbair") [
      {
        key = "LBracket";
        mods = "Alt|Shift";
        chars = "\\u007B"; # {
      }
      {
        key = "RBracket";
        mods = "Alt|Shift";
        chars = "\\u007D"; # }
      }
      {
        key = "LBracket";
        mods = "Alt";
        chars = "\\u005B"; # [
      }
      {
        key = "RBracket";
        mods = "Alt";
        chars = "\\u005D"; # ]
      }
      {
        key = 23;
        mods = "Alt";
        chars = "\\u007E"; # ~
      }
      {
        key = 41;
        mods = "Alt";
        chars = "\\u0040"; # @
      }
      {
        key = 39;
        mods = "Alt";
        chars = "\\u0023"; # #
      }
      {
        key = 10;
        mods = "Alt";
        chars = "\\u0060"; # `
      }
    ];
  };
}
