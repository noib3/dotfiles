{
  keybindings = {
    # Reload sxhkd
    "super + Escape" = "pkill -USR1 -x sxhkd";

    # Launch programs
    "super + Return" = "alacritty";
    "ctrl + w" = "firefox";

    # Toggle fullscreen
    "alt + f" = "bspc node -t ~fullscreen";

    # Toggle float
    "alt + shift + f" = "bspc node -t ~float";

    # Focus windows
    "alt + {Up,Down,Left,Right}" = "bspc node -f {north,south,west,east}";

    # Swap windows
    "ctrl + {Up,Down,Left,Right}" = "bspc node -s {north,south,west,east}";

    # Warp windows
    "super + shift + {Up,Down,Left,Right}" = "bspc node -n {north,south,west,east}";

    # Stack and unstack windows
    # "alt + shift + {k,j,h,l}" = "bspc node -n {north,south,west,east}";

    # Rotate trees
    "alt + {_,shift + }r" = "bspc node -R {270,90}";

    # Focus stacked windows

    # Make windows larger

    # Make windows smaller

    # Move floating windows

    # Send windows to spaces

    # Focus spaces

    # Move spaces

  };
}
