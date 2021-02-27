{ font, theme }:

{
  font   = import (../fonts  + "/${font}"  + /alacritty.nix);
  colors = import (../themes + "/${theme}" + /alacritty.nix);
  cursor.style.blinking = "Never";
  window.decorations    = "buttonless";
}
