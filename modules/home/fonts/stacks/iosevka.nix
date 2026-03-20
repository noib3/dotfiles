{ config, ... }:

let
  fonts = config.modules.fonts;
in
{
  modules.fonts.stacks.iosevka = {
    monospace = fonts.monospace.iosevka-term;
    sansSerif = fonts.sansSerif.iosevka-aile;
    serif = fonts.sansSerif.iosevka-aile;
    emoji = fonts.emoji.noto-color;
  };
}
