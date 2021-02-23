{ font, theme }:

let
  fontt   = import (../fonts  + "/${font}"  + /alacritty.nix);
  colorss = import (../themes + "/${theme}" + /alacritty.nix);
in

{
  font   = fontt;
  colors = colorss;
  cursor.style.blinking = "Never";
  window.decorations    = "buttonless";
}
