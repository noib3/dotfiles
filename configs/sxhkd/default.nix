{ configDir
, cloudDir
, writeShellScriptBin
, writePython3Bin
}:

let
  toggle-gaps = writeShellScriptBin "toggle-gaps"
    (builtins.readFile "${configDir}/bspwm/scripts/toggle-gaps.sh");

  dmenu-bluetooth = writePython3Bin "dmenu-bluetooth" { }
    (builtins.readFile "${configDir}/dmenu/scripts/dmenu-bluetooth.py");

  dmenu-open = writeShellScriptBin "dmenu-open"
    (builtins.readFile "${configDir}/dmenu/scripts/dmenu-open.sh");

  dmenu-pulseaudio = writePython3Bin "dmenu-pulseaudio" { }
    (builtins.readFile "${configDir}/dmenu/scripts/dmenu-pulseaudio.py");

  dmenu-run = writeShellScriptBin "dmenu-run" "dmenu_run -p 'Run>'";

  dmenu-wifi = writePython3Bin "dmenu-wifi" { }
    (builtins.readFile "${configDir}/dmenu/scripts/dmenu-wifi.py");

in
{
  keybindings = {
    # Reload sxhkd
    "super + Escape" = "pkill -USR1 -x sxhkd";

    # Get a shell or launch some other terminal based program
    "super + Return" = "alacritty";
    "super + g" = "alacritty -e btm";
    "super + f" = "alacritty -e lf ~/Downloads";
    "super + a" = ''
      alacritty -e calcurse \
        -C ${builtins.toString ../calcurse} \
        -D ${cloudDir}/share/calcurse
    '';

    # Open the web browser 
    "alt + w" = "qutebrowser";

    # Launch the program runner and the file opener
    "super + o" = "${dmenu-run}/bin/dmenu-run";
    "super + space" = "${dmenu-open}/bin/dmenu-open";

    # Open wifi, bluetooth and shutdown menus
    "alt + shift + b" = "${dmenu-bluetooth}/bin/dmenu-bluetooth";
    "alt + shift + w" = "${dmenu-wifi}/bin/dmenu-wifi";
    "alt + shift + a" = "${dmenu-pulseaudio}/bin/dmenu-pulseaudio";

    # Toggle fullscreen
    "alt + {f,d,g}" = "bspc node -t {~fullscreen,tiled,fullscreen}";

    # Toggle window gaps, borders and paddings
    "alt + s" = "${toggle-gaps}/bin/toggle-gaps";

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
      "${dmenu-pulseaudio}/bin/dmenu-pulseaudio --volume {lower,raise,toggle}";

    # Screenshot either the whole screen or a portion of it and send a
    # notification.
    "super + shift + {3,4}" =
      "flameshot {full, gui} -p ${cloudDir}/screenshots";
  };
}
