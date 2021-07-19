let
  colors = import ./palette.nix;
in
{
  colorscheme = "onedark";

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
