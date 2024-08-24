{
  config,
  lib,
  pkgs,
  palette,
}:

let
  inherit (pkgs.stdenv) isDarwin isLinux;
  colors = import ./colors.nix { inherit palette; };
in
{
  enable = true;

  settings = {
    inherit colors;

    font = import ./font.nix { inherit config; };

    shell = {
      program = "${pkgs.fish}/bin/fish";
      args = [ "--interactive" ];
    };

    window =
      with lib.attrsets;
      optionalAttrs isDarwin { decorations = "buttonless"; }
      # // optionalAttrs config.machine.skunk.isCurrent {
      // optionalAttrs true {
        padding = {
          x = 10;
          y = 5;
        };
      };

    cursor.style = "Beam";

    keyboard.bindings =
      [
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
          key = "=";
          mods = "Super";
          action = "IncreaseFontSize";
        }
        {
          key = "-";
          mods = "Super";
          action = "DecreaseFontSize";
        }
        {
          key = "0";
          mods = "Super";
          action = "ResetFontSize";
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
      ]
      ++ lib.lists.optionals isLinux [
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
      ];
  };
}
