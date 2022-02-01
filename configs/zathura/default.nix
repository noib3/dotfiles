{ colorscheme, font-family, palette, hexlib }:

let
  colors = import ./colors.nix { inherit colorscheme palette hexlib; };
  font = import ./font.nix { family = font-family; };
in
{
  options = {
    font = "${font-family} Regular ${toString font.size}";

    default-bg = colors.default.bg;
    default-fg = colors.default.fg;

    inputbar-bg = colors.inputbar.bg;
    inputbar-fg = colors.inputbar.fg;

    highlight-color = colors.highlight.bg;

    guioptions = "";
    selection-clipboard = "clipboard";
    highlight-transparency = "0.40";
  };
}
