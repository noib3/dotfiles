{ pkgs }:

{
  enable = pkgs.stdenv.isDarwin;
  skhdConfig = builtins.readFile ./skhdrc;
}

# { writeShellScriptBin }:

# let
#   take-screenshot = writeShellScriptBin "take-screenshot"
#     (import ./take-screenshot.sh.nix);
# in
# {
#   config = ''
#     cmd - return : alacritty
#     alt - return : alacritty --title "floating"
#     cmd - f : alacritty -e fish -c "lf $HOME/Downloads"
#     cmd - p : alacritty -e fish -c "ipython --no-confirm-exit"
#     cmd - a : alacritty -e calcurse \
#                 -C ${builtins.toString ../calcurse} \
#                 -D $SYNCDIR/calcurse
#     cmd - g : alacritty -e btm
#     cmd - o : $SCRIPTSDIR/fuzzy-opener/fuzzy-opener
#     ctrl - w : open -na ~/.nix-profile/Applications/Firefox.app

#     cmd - d [
#       "Firefox" : skhd --key "f4"
#     ]

#     cmd - e [
#       "Firefox" : skhd --key "shift + alt - y"
#     ]

#     cmd - s [
#       "Firefox" : false
#     ]

#     cmd - h [
#       "Alacritty" ~
#       "Firefox" : skhd --key "shift + cmd - h"
#       * : false
#     ]

#     # Toggle fullscreen
#     alt - f : skhd --key "ctrl + cmd - f"

#     # Toggle float
#     alt + shift - f : yabai -m window --toggle float

#     # Focus windows
#     alt - up : yabai -m window --focus north
#     alt - down : yabai -m window --focus south
#     alt - left : yabai -m window --focus west
#     alt - right : yabai -m window --focus east

#     # Swap windows
#     ctrl - up : yabai -m window --swap north
#     ctrl - down : yabai -m window --swap south
#     ctrl - left : yabai -m window --swap west
#     ctrl - right : yabai -m window --swap east

#     # Warp windows
#     cmd + shift - up : yabai -m window --warp north
#     cmd + shift - down : yabai -m window --warp south
#     cmd + shift - left : yabai -m window --warp west
#     cmd + shift - right : yabai -m window --warp east

#     # Stack and unstack windows
#     alt + shift - k : yabai -m window --stack north
#     alt + shift - j : yabai -m window --stack south
#     alt + shift - h : yabai -m window --stack west
#     alt + shift - l : yabai -m window --stack east
#     alt + shift - u : yabai -m window --toggle float \
#                         && yabai -m window --toggle float

#     # Focus stacked windows
#     alt + shift - up : yabai -m window --focus stack.prev
#     alt + shift - down : yabai -m window --focus stack.next

#     # Make windows larger
#     alt - h : yabai -m window --resize left:-25:0
#     alt - j : yabai -m window --resize bottom:0:25
#     alt - k : yabai -m window --resize top:0:-25
#     alt - l : yabai -m window --resize right:25:0

#     # Make windows smaller
#     ctrl - h : yabai -m window --resize right:-25:0
#     ctrl - j : yabai -m window --resize top:0:25
#     ctrl - k : yabai -m window --resize bottom:0:-25
#     ctrl - l : yabai -m window --resize left:25:0

#     # Move floating windows
#     alt + cmd - up : yabai -m window --move rel:0:-25
#     alt + cmd - down : yabai -m window --move rel:0:25
#     alt + cmd - left : yabai -m window --move rel:-25:0
#     alt + cmd - right : yabai -m window --move rel:25:0

#     # Move windows to spaces and follow focus
#     alt + cmd - 1 : yabai -m window --space 1 && yabai -m space --focus 1
#     alt + cmd - 2 : yabai -m window --space 2 && yabai -m space --focus 2
#     alt + cmd - 3 : yabai -m window --space 3 && yabai -m space --focus 3
#     alt + cmd - 4 : yabai -m window --space 4 && yabai -m space --focus 4
#     alt + cmd - 5 : yabai -m window --space 4 && yabai -m space --focus 5
#     alt + cmd - n : yabai -m space --create \
#                       && yabai -m window --space last \
#                       && yabai -m space --focus last

#     # Focus spaces
#     alt - 1 : yabai -m space --focus 1
#     alt - 2 : yabai -m space --focus 2
#     alt - 3 : yabai -m space --focus 3
#     alt - 4 : yabai -m space --focus 4

#     # Move spaces
#     ctrl + cmd - 1 : yabai -m space --move 1
#     ctrl + cmd - 2 : yabai -m space --move 2
#     ctrl + cmd - 3 : yabai -m space --move 3
#     ctrl + cmd - 4 : yabai -m space --move 4
#     ctrl + cmd - 5 : yabai -m space --move 5

#     # Create, mirror, balance, rotate, destroy spaces
#     alt - n : yabai -m space --create && yabai -m space --focus last
#     alt - y : yabai -m space --mirror y-axis
#     alt - b : yabai -m space --balance
#     alt - r : yabai -m space --rotate 270
#     alt + shift - r : yabai -m space --rotate 90
#     alt - w : yabai -m space --focus prev \
#                 && yabai -m space recent --destroy \
#                 || yabai -m space --destroy
#     alt + cmd - w : yabai -m window --close \
#                       && yabai -m space --focus prev \
#                       && yabai -m space recent --destroy

#     # Screenshot either the whole screen or a portion of it and send a
#     # notification.
#     shift + cmd - 3 : ${take-screenshot}/bin/take-screenshot whole
#     shift + cmd - 4 : ${take-screenshot}/bin/take-screenshot portion
#   '';
# }
