let
  colors = import ./palette.nix;
in
{
  colorscheme = "afterglow";

  terminal = colors.normal;

  highlights = rec {
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

    "pandocEmphasis" = htmlItalic;

    "pandocStrong" = htmlBold;

    "FzfBorder" = {
      guifg = "#393939";
    };

    "FloatermBorder" = {
      guibg = "#393939";
    };
  };
}
