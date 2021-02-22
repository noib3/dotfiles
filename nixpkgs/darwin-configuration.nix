{ config, pkgs, ... }:

{
  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin-configuration.nix
  environment.darwinConfig = "$HOME/.config/nixpkgs/darwin-configuration.nix";

  system.defaults = {
    NSGlobalDomain = {
      # Autohide the menu bar.
      _HIHideMenuBar = true;

      # Set really short keyboard key repeat delays.
      InitialKeyRepeat = 10;
      KeyRepeat = 1;

      # Show scroll bars only when scrolling.
      AppleShowScrollBars = "WhenScrolling";
    };

    dock = {
      # Autohide the dock and set a really long show-on-hover delay.
      autohide = true;
      # autohide-delay = 1000;

      # Set the dock size.
      tilesize = 50;

      # Empty the dock.
      # persistent-apps = [];
      # persistent-others = [];
      # recent-others = [];
      show-recents = false;

      # Don't rearrange spaces based on most recent use.
      mru-spaces = false;
    };

    finder = {
      # Enable quitting the Finder.
      QuitMenuItem = true;

      # Show all files and extensions.
      # AppleShowAllFiles = true;

      # Don't show warnings before changing an extension.
      FXEnableExtensionChangeWarning = false;

      # Group and sort files by name.
      # FXPreferredGroupBy = "Name";

      # Make $HOME the default directory when opening a new window.
      # NewWindowTarget = "PfLo";
      # NewWindowTargetPath = "file://$HOME/";
    };
  };

  services = {
    # skhd = {
    #   enable = true;
    #   package = pkgs.skhd;
    #   skhdConfig = ''
    #     cmd - return : alacritty
    #     alt - return : alacritty --title "floating"
    #     cmd - f : alacritty --command fish -c "lf $HOME/Downloads"
    #     cmd - p : alacritty --command fish -c "ipython --no-confirm-exit"
    #     cmd - a : alacritty --command calcurse -C "$HOME/.config/calcurse" -D "$PRIVATEDIR/calcurse"
    #     cmd - g : alacritty --command gotop
    #     cmd - o : $SCRIPTSDIR/fuzzy-opener/fuzzy-opener
    #     ctrl - w : open -na /Applications/Firefox.app

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

    #     # Screenshot the whole screen and send a notification (uses fish syntax)
    #     shift + cmd - 3 : \
    #       set sshot "$SSHOTDIR"/(date +%4Y-%b-%d@%T).png \
    #         && screencapture -mx "$sshot" \
    #         && terminal-notifier \
    #               -title "New screenshot" \
    #               -subtitle (basename "$sshot") \
    #               -message "Saved in "(dirname "$sshot") \
    #               -appIcon "$HOME/.config/skhd/picture-icon.png" \
    #               -contentImage "$sshot" \
    #               -execute "open \"$sshot\""

    #     # Screenshot a portion of the screen and send a notification if the screenshot
    #     # wasn't cancelled (uses fish syntax).
    #     shift + cmd - 4 : \
    #       set sshot "$SSHOTDIR"/(date +%4Y-%b-%d@%T).png \
    #         && screencapture -imx "$sshot" \
    #         && ls "$sshot" \
    #         && terminal-notifier \
    #               -title "New screenshot" \
    #               -subtitle (basename "$sshot") \
    #               -message "Saved in "(dirname "$sshot") \
    #               -appIcon "$HOME/.config/skhd/picture-icon.png" \
    #               -contentImage "$sshot" \
    #               -execute "open \"$sshot\""
    #   '';
    # };

    # yabai = {
    #   enable = true;
    #   package = pkgs.yabai;
    #   enableScriptingAddition = true;

    #   config = {
    #     window_placement           = "second_child";
    #     window_shadow              = "on";
    #     window_border              = "on";
    #     window_border_width        = 5;
    #     normal_window_border_color = "0xff3e4452";
    #     active_window_border_color = "0xffabb2bf";
    #     layout                     = "bsp";
    #     top_padding                = 30;
    #     bottom_padding             = 30;
    #     left_padding               = 40;
    #     right_padding              = 40;
    #     window_gap                 = 30;
    #   };

    #   extraConfig = ''
    #     SPACEBAR_HEIGHT=$(spacebar -m config height)
    #     yabai -m config external_bar all:''${SPACEBAR_HEIGHT}:0

    #     yabai -m rule --add app="Digital Colour Meter" manage=off
    #     yabai -m rule --add app="System Preferences"   manage=off
    #     yabai -m rule --add app="Activity Monitor"     manage=off
    #     yabai -m rule --add app="Font Book"            manage=off
    #     yabai -m rule --add app="App Store"            manage=off
    #     yabai -m rule --add app="System Information"   manage=off
    #     yabai -m rule --add app="Logi Options"         manage=off
    #     yabai -m rule --add title="floating"           manage=off

    #     # https://github.com/koekeishiya/yabai/issues/719

    #     # focus window after active space changes
    #     yabai -m signal --add event=space_changed \
    #       action="yabai -m window --focus \$(yabai -m query --windows --space | jq .[0].id)"

    #     # focus window after active display changes
    #     yabai -m signal --add event=display_changed \
    #       action="yabai -m window --focus \$(yabai -m query --windows --space | jq .[0].id)"
    #   '';
    # };

    # spacebar = {
    #   enable = true;
    #   package = pkgs.spacebar;
    #   config = {
    #     height = 26;
    #     spacing_left = 30;
    #     spacing_right = 60;
    #     text_font = ''"RobotoMono Nerd Font:Regular:22.0"'';
    #     icon_font = ''"RobotoMono Nerd Font:Regular:22.0"'';
    #     background_color = "0xff3e4452";
    #     foreground_color = "0xffabb2bf";
    #     space_icon_color = "0xffe5c07b";
    #     space_icon_strip = "1 2 3 4 5";
    #     power_icon_strip = "  ";
    #     clock_icon = "";
    #     clock_format = ''"%a %d %b %R"'';
    #   };
    # };
  };
}
