{ config, ... }:

let
  fonts = config.modules.fonts;
in
{
  modules.fonts.stacks.fira = {
    monospace = fonts.monospace.fira-code;
    sansSerif = fonts.sansSerif.fira-sans;
    serif = fonts.sansSerif.fira-sans;
    emoji = fonts.emoji.noto-color;
  };
}
