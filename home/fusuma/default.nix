{ pkgs }:

{
  extraPackages = with pkgs; [
    xdotool
  ];

  settings = {
    swipe = {
      "3" = {
        left = "xdotool key shift+l";
        right = "xdotool key shift+h";
      };

      "4" = {
        up = "xdotool key alt+g";
        down = "xdotool key alt+d";
        left = "xdotool key ctrl+shift+Right";
        right = "xdotool key ctrl+shift+Left";
      };
    };
  };
}
