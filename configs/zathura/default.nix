{
  config,
  pkgs,
}:

let
  colors = import ./colors.nix { inherit config; };
in
{
  enable = pkgs.stdenv.isLinux;

  options = {
    font =
      let
        font = config.fonts.serif;
        size = toString (font.size config "zathura");
      in
      "${font.name} ${size}";

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
