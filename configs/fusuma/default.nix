let
  xdotool = "${(import <nixpkgs> { }).xdotool}/bin/xdotool";
in
{
  settings = {
    swipe = {
      "3" = {
        left.command = "${xdotool} key shift+l";
        right.command = "${xdotool} key shift+h";
      };

      "4" = {
        up.command = "${xdotool} key alt+g";
        down.command = "${xdotool} key alt+d";
        left.command = "${xdotool} key ctrl+shift+Right";
        right.command = "${xdotool} key ctrl+shift+Left";
      };
    };
  };
}
