let
  colors = import ./palette.nix;
in
{
  colorscheme = "onedark";

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

    "Statusline" = {
      guibg = colors.normal.black;
    };

    "StatuslineNC" = {
      guibg = colors.normal.black;
    };

    "VertSplit" = {
      guifg = colors.bright.white;
      guibg = "NONE";
    };

    "htmlItalic" = {
      guifg = colors.normal.magenta;
      gui = "italic";
    };

    "htmlBold" = {
      guifg = colors.normal.yellow;
      gui = "bold";
    };

    "pandocEmphasis" = htmlItalic;

    "pandocStrong" = htmlBold;

    "LspReferenceRead" = {
      guibg = colors.bright.black;
    };

    "LspReferenceText" = {
      guibg = colors.bright.black;
    };

    "LspReferenceWrite" = {
      guibg = colors.bright.black;
    };

    "Whitespace" = {
      guifg = colors.bright.white;
    };

    "FzfBorder" = {
      guifg = colors.bright.white;
    };
  };
}
