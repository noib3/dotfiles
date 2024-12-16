{ config }:

let
  inherit (config.modules.colorscheme) name palette;
  overrides = {
    tokyonight = {
      orange = "#ff9e64";
      gray = "#565f89";
    };
    vscode = {
      orange = "#ce9178";
      gray = "#5a5a5a";
    };
  };
in
{
  inherit (palette.normal)
    black
    red
    green
    yellow
    blue
    magenta
    cyan
    ;
  orange = overrides.${name}.orange or palette.bright.yellow;
  gray = overrides.${name}.gray or palette.bright.white;
}
