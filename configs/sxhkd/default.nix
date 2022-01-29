let
  pkgs = import <nixpkgs> { };
in
{
  keybindings = {
    # Reload sxhkd
    "super + Escape" = "pkill -USR1 -x sxhkd";

    # Get a shell or launch some other terminal based program
    "super + Return" = "nvidia-offload alacritty";
    "super + g" = "nvidia-offload alacritty -e gotop";
    "super + f" = "nvidia-offload alacritty -e lf ~/Downloads";
    "super + a" = ''
      nvidia-offload alacritty -e calcurse \
        -C ${builtins.toString ../calcurse} \
        -D $SYNCDIR/share/calcurse
    '';

    # Open the web browser 
    "alt + w" = "nvidia-offload qutebrowser";

    # Launch the program runner and the file opener
    "super + o" = "dmenu-run";
    "super + space" = "dmenu-open";

    # Open wifi, bluetooth and shutdown menus
    "alt + shift + b" = "dmenu-bluetooth";
    "alt + shift + w" = "dmenu-wifi";
    "alt + shift + p" = "dmenu-powermenu";
    "alt + shift + a" = "dmenu-pulseaudio";

    # Toggle fullscreen
    "alt + {f,d,g}" = "bspc node -t {~fullscreen,tiled,fullscreen}";

    # Toggle window gaps, borders and paddings
    "alt + s" = "toggle-gaps";

    # Toggle float
    "alt + shift + f" = "bspc node -t ~floating";

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
    "alt + {h,j,k,l}" =
      "bspc node -z {left -25 0,bottom 0 25,top 0 -25,right 25 0}";

    # Make windows smaller
    "ctrl + {h,j,k,l}" =
      "bspc node -z {right -25 0,top 0 25,bottom 0 -25,left 25 0}";

    # Balance and mirror desktops
    "alt + {b,y,x}" = "bspc node @/ {-B,-F vertical,-F horizontal}";

    # Focus or send window to the given desktop
    "ctrl + shift + {Left,Right}" = "bspc desktop -f {prev,next}";

    # Focus or send window to the given desktop
    "alt + {_,super + }{1-6}" = "bspc {desktop -f,node -d} '^{1-6}'";

    # Control audio volume
    "XF86Audio{LowerVolume,RaiseVolume,Mute}" =
      "dmenu-pulseaudio --volume {lower,raise,toggle}";

    # Screenshot either the whole screen or a portion of it and send a
    # notification.
    "super + shift + {3,4}" = "flameshot {full, gui} -p ~/Dropbox/screenshots";
  };
}
