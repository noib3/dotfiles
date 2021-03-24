{
  keybindings = {
    # Reload sxhkd
    "super + Escape" = "pkill -USR1 -x sxhkd";

    # Open the terminal
    "super + Return" = "alacritty";
    "super + f" = "alacritty --command fish -c 'lf $HOME/Downloads'";
    "super + a" = "alacritty --command calcurse -C $HOME/.config/calcurse -D $SECRETSDIR/calcurse";
    "super + g" = "alacritty --command gotop";

    # Open the web browser 
    # "alt + w" = "firefox";
    "alt + w" = "qutebrowser";

    # Launch the file opener
    "super + space" = "rofi -show drun";

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

    # Kill windows
    "super + q" = "bspc node -k";

    # Rotate trees
    "alt + {_,shift + }r" = "bspc node @/ -R {90,-90}";

    # Focus stacked windows

    # Make windows larger

    # Make windows smaller

    # Move floating windows

    # Cycle desktops
    "ctrl + shift + {Left,Right}" = "bspc desktop -f {prev,next}";

    # Focus or send window to the given desktop
    "alt + {_,super + }{1-5}" = "bspc {desktop -f,node -d} '^{1-5}'";

    # Move desktops
    "ctrl + super + {1,5}" = "bspc desktop -s '{1-5}'";

    # Screenshot the whole screen
    "super + shift + 3" = ''
      set sshot /home/noib3/Sync/screenshots/(date +%4Y-%b-%d@%T).png \
        && import -window root $sshot
    '';

    # Screenshot a portion of the screen
    "super + shift + 4" = ''
      set sshot /home/noib3/Sync/screenshots/(date +%4Y-%b-%d@%T).png \
        && import $sshot
    '';
  };
}
