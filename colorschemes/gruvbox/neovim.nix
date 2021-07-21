let
  colors = import ./palette.nix;
in
{
  colorscheme = "gruvbox";

  terminal = colors.normal;

  highlights = {
    "SpellBad" = {
      guifg = colors.normal.red;
      gui = "undercurl";
    };

    "SpellCap" = {
      guifg = colors.normal.yellow;
      gui = "NONE";
    };

    "VertSplit" = {
      guifg = colors.bright.white;
      guibg = "NONE";
    };

    "StatusLine" = {
      guifg = "NONE";
      guibg = colors.bright.blue;
    };

    "htmlItalic" = {
      guifg = colors.normal.magenta;
      gui = "italic";
    };

    "htmlBold" = {
      guifg = colors.normal.yellow;
      gui = "bold";
    };

    "FzfBorder" = {
      guifg = colors.bright.white;
    };
  };
}
