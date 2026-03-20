{ config, ... }:

let
  fonts = config.modules.fonts;
in
{
  modules.fonts.stacks.docsrs = {
    monospace = fonts.monospace.source-code-pro;
    sansSerif = fonts.sansSerif.fira-sans;
    serif = fonts.serif.source-serif;
    emoji = fonts.emoji.noto-color;
  };
}
