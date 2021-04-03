{
  settings = {
    cursor.style.blinking = "Never";

    window = {
      decorations = "buttonless";
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
    ];
  };
}
