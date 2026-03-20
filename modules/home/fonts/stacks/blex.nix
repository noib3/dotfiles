{ config, ... }:

let
  fonts = config.modules.fonts;
in
{
  modules.fonts.stacks.blex = {
    monospace = fonts.monospace.blex-mono;
    sansSerif = fonts.monospace.blex-mono;
    serif = fonts.monospace.blex-mono;
    emoji = fonts.emoji.noto-color;
  };
}
