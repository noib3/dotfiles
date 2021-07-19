let
  colors = import ./palette.nix;
in
{
  colorscheme = "afterglow";

  terminal = colors.normal;

  highlights = {
    "SpellBad" = {
      guifg = colors.normal.red;
      gui = "undercurl";
    };

    "SpellCap" = {
      guifg = colors.bright.yellow;
      gui = "NONE";
    };

    "VertSplit" = {
      guifg = colors.bright.white;
      guibg = "NONE";
    };

    "Visual" = {
      guifg = colors.normal.white;
      guibg = colors.bright.black;
    };

    "htmlItalic" = {
      guifg = colors.normal.cyan;
      gui = "italic";
    };

    "htmlBold" = {
      guifg = colors.bright.yellow;
      gui = "bold";
    };

    "FzfBorder" = {
      guifg = colors.bright.white;
    };
  };
}
