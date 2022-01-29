{ colorscheme, palette }:

let
  c = {
    "afterglow" = {
      fg = palette.normal.white;
      focused-workspace.fg = palette.normal.yellow;
    };
  };
in
{
  fg = c.${colorscheme}.fg or palette.bright.white;
  bg = palette.bright.black;
  focused-workspace.fg =
    c.${colorscheme}.focused-workspace.fg
      or palette.bright.yellow;
}
