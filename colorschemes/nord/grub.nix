let
  colors = import ./palette.nix;
in
{
  boot-entry = {
    fg = colors.normal.white;
    selected.bg = colors.normal.blue;
    selected.fg = colors.normal.black;
  };
  countdown-message.fg = colors.normal.blue;
  navigation-keys-message.fg = colors.bright.white;
}
