{ secrets-directory, screenshots-directory }:
let
  pa-sink = "bluez_sink.5C_44_3E_31_27_86.a2dp_sink";
in
{
  keybindings = {
    # Reload sxhkd
    "super + Escape" = "pkill -USR1 -x sxhkd";

    # Get a shell or launch some other terminal based program
    "super + Return" = "alacritty";
    "super + g" = "alacritty --command gotop";
    "super + f" = "alacritty --command fish -c 'lf $HOME/Downloads'";
    "super + a" = ''
      alacritty --command calcurse \
        -C $HOME/.config/calcurse -D ${secrets-directory}/calcurse
    '';

    # Open the web browser 
    "alt + w" = "qutebrowser";

    # Launch the file opener
    "super + space" = "rofi -show drun";

    # Toggle fullscreen
    "alt + f" = "bspc node -t ~fullscreen";
    "alt + d" = "bspc node -t tiled";
    "alt + g" = "bspc node -t fullscreen";

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
    # "alt + shift + {Up,Down}" = "";

    # Make windows larger
    # "alt + {h,j,k,l}" = "bspc node -z {left,bottom,top,right} {-25 0,0 25,0 -25,25 0}";
    "alt + h" = "bspc node -z left -25 0";
    "alt + j" = "bspc node -z bottom 0 25";
    "alt + k" = "bspc node -z top 0 -25";
    "alt + l" = "bspc node -z right 25 0";

    # Make windows smaller
    # "ctrl + {h,j,k,l}" = "bspc node -z {left,bottom,top,right} {25 0,0 -25,0 25,-25 0}";
    "ctrl + h" = "bspc node -z right -25 0";
    "ctrl + j" = "bspc node -z top 0 25";
    "ctrl + k" = "bspc node -z bottom 0 -25";
    "ctrl + l" = "bspc node -z left 25 0";

    # Balance and mirror desktops
    "alt + b" = "bspc node @/ -B";
    "alt + y" = "bspc node @/ -F vertical";
    "alt + x" = "bspc node @/ -F horizontal";

    # Focus or send window to the given desktop
    "ctrl + shift + {Left,Right}" = "bspc desktop -f {prev,next}";

    # Focus or send window to the given desktop
    "alt + {_,super + }{1-5}" = "bspc {desktop -f,node -d} '^{1-5}'";

    # Control audio volume
    "XF86Audio{LowerVolume,RaiseVolume}" = "pactl set-sink-volume ${pa-sink} {-,+}5%";
    "XF86AudioMute" = "pactl set-sink-mute ${pa-sink} toggle";

    # Screenshot the whole screen
    "super + shift + 3" = ''
      set sshot ${screenshots-directory}/(date +%4Y-%b-%d@%T).png \
        && import -window root $sshot
    '';

    # Screenshot a portion of the screen
    "super + shift + 4" = ''
      set sshot ${screenshots-directory}/(date +%4Y-%b-%d@%T).png \
        && import $sshot
    '';
  };
}
