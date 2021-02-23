{
  font = {
    normal = {
      family = "RobotoMono Nerd Font";
      style = "Regular";
    };

    bold = {
      family = "RobotoMono Nerd Font";
      style = "Bold";
    };

    italic = {
      family = "RobotoMono Nerd Font";
      style = "Italic";
    };

    bold_italic = {
      family = "RobotoMono Nerd Font";
      style = "Bold Italic";
    };

    size = 24;
    offset.y = 2;
  };

  colors = {
    primary = {
      foreground = "#abb2bf";
      background = "#282c34";
    };

    cursor = {
      text =   "#5c6370";
      cursor = "#abb2bf";
    };

    normal = {
      black =   "#5c6370";
      red =     "#e06c75";
      green =   "#98c379";
      yellow =  "#e5c07b";
      blue =    "#61afef";
      magenta = "#c678dd";
      cyan =    "#56b6c2";
      white =   "#abb2bf";
    };

    bright = {
      black =   "#4b5263";
      red =     "#be5046";
      green =   "#98c379";
      yellow =  "#d19a66";
      blue =    "#61afef";
      magenta = "#c678dd";
      cyan =    "#56b6c2";
      white =   "#3e4452";
    };
  };

  window = {
    padding.x = 14;
    padding.y = 6;
  };

  key_bindings = [
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
      chars ="\\x7E"; # ~
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
  ];
}
