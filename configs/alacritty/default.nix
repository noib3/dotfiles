{ font-family, machine, palette, pkgs ? import <nixpkgs> { }, shell }:

let
  font = import ./font.nix { family = font-family; inherit machine; };
  colors = import ./colors.nix { inherit palette; };
in
{
  settings = {
    inherit shell font colors;

    window = (
      if pkgs.stdenv.isLinux then
        {
          padding = {
            x = 3;
            y = 0;
          };
        }
      else if pkgs.stdenv.isDarwin then
        {
          decorations = "buttonless";
          padding = {
            x = 14;
            y = 6;
          };
        }
      else { }
    );

    cursor.style = "Beam";

    key_bindings = [
      {
        key = "D";
        mods = "Super";
        chars = "\\x18\\x04"; # C-x C-d
      }
      {
        key = "E";
        mods = "Super";
        chars = "\\x18\\x05"; # C-x C-e
      }
      {
        key = "H";
        mods = "Super";
        chars = "\\x18\\x06"; # C-x C-f
      }
      {
        key = "R";
        mods = "Super";
        chars = "\\x18\\x12"; # C-x C-r
      }
      {
        key = "K";
        mods = "Super";
        chars = "\\x18\\x07"; # C-x C-g
      }
      {
        key = "L";
        mods = "Super";
        chars = "\\x07"; # C-g
      }
      {
        key = "S";
        mods = "Super";
        chars = "\\x13"; # C-s
      }
      {
        key = "T";
        mods = "Super";
        chars = "\\x14"; # C-t
      }
      {
        key = "W";
        mods = "Super";
        chars = "\\x17"; # C-w
      }
      {
        key = "Up";
        mods = "Super";
        chars = "\\x15"; # C-u
      }
      {
        key = "Down";
        mods = "Super";
        chars = "\\x04"; # C-d
      }
      {
        key = "Left";
        mods = "Super";
        chars = "\\x01"; # C-a
      }
      {
        key = "Right";
        mods = "Super";
        chars = "\\x05"; # C-e
      }
      {
        key = "Back";
        mods = "Super";
        chars = "\\x15"; # C-u
      }
      {
        key = "Key1";
        mods = "Super";
        chars = "\\x1b\\x4f\\x50"; # F1
      }
      {
        key = "Key2";
        mods = "Super";
        chars = "\\x1b\\x4f\\x51"; # F2
      }
      {
        key = "Key3";
        mods = "Super";
        chars = "\\x1b\\x4f\\x52"; # F3
      }
      {
        key = "Key4";
        mods = "Super";
        chars = "\\x1b\\x4f\\x53"; # F4
      }
      {
        key = "Key5";
        mods = "Super";
        chars = "\\x1b\\x5b\\x31\\x35\\x7e"; # F5
      }
      {
        key = "Key6";
        mods = "Super";
        chars = "\\x1b\\x5b\\x31\\x37\\x7e"; # F6
      }
      {
        key = "Key7";
        mods = "Super";
        chars = "\\x1b\\x5b\\x31\\x38\\x7e"; # F7
      }
      {
        key = "Key8";
        mods = "Super";
        chars = "\\x1b\\x5b\\x31\\x39\\x7e"; # F8
      }
      {
        key = "Key9";
        mods = "Super";
        chars = "\\x1b\\x5b\\x32\\x30\\x7e"; # F9
      }
    ] ++ (
      if pkgs.stdenv.isLinux then
        [
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

        ]
      else if pkgs.stdenv.isDarwin then
        [
          {
            key = "LBracket";
            mods = "Alt|Shift";
            chars = "\\x7B"; # {
          }
          {
            key = "RBracket";
            mods = "Alt|Shift";
            chars = "\\x7D"; # }
          }
          {
            key = "LBracket";
            mods = "Alt";
            chars = "\\x5B"; # [
          }
          {
            key = "RBracket";
            mods = "Alt";
            chars = "\\x5D"; # ]
          }
          {
            key = 23;
            mods = "Alt";
            chars = "\\x7E"; # ~
          }
          {
            key = 41;
            mods = "Alt";
            chars = "\\x40"; # @
          }
          {
            key = 39;
            mods = "Alt";
            chars = "\\x23"; # #
          }
          {
            key = 10;
            mods = "Alt";
            chars = "\\x60"; # `
          }
        ]
      else
        [ ]
    );
  };
}
