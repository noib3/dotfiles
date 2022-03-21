{ colorscheme
, palette
}:

let
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
  inherit (palette.normal) black red green yellow blue magenta cyan;
  orange = overrides.${colorscheme}.orange or palette.bright.yellow;
  gray = overrides.${colorscheme}.gray or palette.bright.white;
}
