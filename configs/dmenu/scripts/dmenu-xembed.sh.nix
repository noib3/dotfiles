{
  colorscheme,
  font-family,
  palette,
  pkgs ? import <nixpkgs> { },
}:

let
  colors =
    (import ../../qutebrowser/colors.nix { inherit colorscheme palette; }).dmenu;
  font = (import ../../qutebrowser/font.nix { family = font-family; }).dmenu;
in
''
  dmenu \
    -fn '${font-family}:size=${toString font.size}' \
    -h '${toString font.lineheight}' \
    -nb '${colors.normal.bg}' \
    -nf '${colors.normal.fg}' \
    -pb '${colors.prompt.bg}' \
    -pf '${colors.prompt.fg}' \
    -sb '${colors.selected.bg}' \
    -sf '${colors.selected.fg}' \
    -nhb '${colors.normal.bg}' \
    -nhf '${colors.highlight.fg}' \
    -shb '${colors.selected.bg}' \
    -shf '${colors.highlight.fg}' \
    -w "$(${pkgs.xdotool}/bin/xdotool getactivewindow)" \
    "$@"
''
