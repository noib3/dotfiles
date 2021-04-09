{
  keybindings = {
    # Reload sxhkd
    "super + Escape" = "pkill -USR1 -x sxhkd";

    # Get a shell or launch some other terminal based program
    "super + Return" = "alacritty";
    "super + {g,f,a}" = "alacritty -e {gotop,fish -c 'lf $HOME/Downloads',calcurse}";

    # Open the web browser 
    "alt + w" = "qutebrowser";

    # Launch the file opener
    "super + space" = "fuzzy-opener";

    # Toggle fullscreen
    "alt + {f,d,g}" = "bspc node -t {~fullscreen,tiled,fullscreen}";

    # Toggle window gaps, borders and paddings
    "alt + s" = "toggle-gaps-borders-paddings {off,on}";

    # Toggle float
    "alt + shift + f" = "bspc node -t ~float";

    # Focus windows
    "alt + {Up,Down,Left,Right}" = "bspc node -f {north,south,west,east}";

    # Swap windows
    "ctrl + {Up,Down,Left,Right}" = "bspc node -s {north,south,west,east}";

    # Warp windows
    "super + shift + {Up,Down,Left,Right}" = "bspc node -n {north,south,west,east}";

    # Kill windows
    "super + q" = "bspc node -k";

    # Rotate trees
    "alt + {_,shift + }r" = "bspc node @/ -R {90,-90}";

    # Make windows larger
    "alt + {h,j,k,l}" = "bspc node -z {left -25 0,bottom 0 25,top 0 -25,right 25 0}";

    # Make windows smaller
    "ctrl + {h,j,k,l}" = "bspc node -z {right -25 0,top 0 25,bottom 0 -25,left 25 0}";

    # Balance and mirror desktops
    "alt + {b,y,x}" = "bspc node @/ {-B,-F vertical,-F horizontal}";

    # Focus or send window to the given desktop
    "ctrl + shift + {Left,Right}" = "bspc desktop -f {prev,next}";

    # Focus or send window to the given desktop
    "alt + {_,super + }{1-5}" = "bspc {desktop -f,node -d} '^{1-5}'";

    # Control audio volume
    "XF86Audio{LowerVolume,RaiseVolume,Mute}" = "volumectl {lower,raise,mute}";

    # Screenshot either the whole screen or a portion of it and send a
    # notification.
    "super + shift + {3,4}" = "take-screenshot {whole, portion}";
  };
}
