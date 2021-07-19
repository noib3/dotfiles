let
  colors = import ./palette.nix;
in
{
  boot-entry.fg = colors.normal.white;
  boot-entry.selected.fg = colors.normal.black;
  boot-entry.selected.bg = colors.normal.blue;
  countdown-message.fg = colors.normal.blue;
  navigation-keys-message.fg = colors.bright.white;
}
