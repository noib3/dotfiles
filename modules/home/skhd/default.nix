{
  config,
  lib,
  pkgs,
  ...
}:

# NOTE: you need to grant skhd access to the accessibility API for it to start
# working. Unfortunately Apple doesn't let you do that programmatically, so
# you'll have to go click these buttons:
#
# - System Settings > Privacy & Security > Accessibility;
# - click the '+' icon;
# - press cmd-shift-g to open "Go to folder";
# - paste "~/.local/state/nix/profile/bin";
# - select the skhd binary;
with lib;
let
  cfg = config.modules.skhd;
  take-screenshot = pkgs.writeShellScriptBin "take-screenshot" (
    import ./take-screenshot.sh.nix
  );
in
{
  options.modules.skhd = {
    enable = mkEnableOption "skhd";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "skhd is only available on macOS";
      }
    ];

    services.skhd = {
      enable = true;

      config = ''
        # Launch apps.
        cmd - return : ${config.modules.terminals.enabled.launchCommand}

        # Toggle fullscreen.
        alt - f : skhd --key "ctrl + cmd - f"

        # Screenshot either the whole screen or a portion of it and send a
        # notification.
        # shift + cmd - 3 : ${lib.getExe take-screenshot} whole
        # shift + cmd - 4 : ${lib.getExe take-screenshot} portion
      ''
      + (
        let
          yabai = lib.getExe config.services.yabai.package;
        in
        lib.optionalString config.modules.yabai.enable ''
          # Focus windows.
          alt - up : ${yabai} -m window --focus north
          alt - down : ${yabai} -m window --focus south
          alt - left : ${yabai} -m window --focus west
          alt - right : ${yabai} -m window --focus east

          # Swap windows
          # ctrl - up : ${yabai} -m window --swap north
          # ctrl - down : ${yabai} -m window --swap south
          # ctrl - left : ${yabai} -m window --swap west
          # ctrl - right : ${yabai} -m window --swap east

          # Warp windows
          # cmd + shift - up : ${yabai} -m window --warp north
          # cmd + shift - down : ${yabai} -m window --warp south
          # cmd + shift - left : ${yabai} -m window --warp west
          # cmd + shift - right : ${yabai} -m window --warp east

          # Stack and unstack windows
          # alt + shift - k : ${yabai} -m window --stack north
          # alt + shift - j : ${yabai} -m window --stack south
          # alt + shift - h : ${yabai} -m window --stack west
          # alt + shift - l : ${yabai} -m window --stack east
          # alt + shift - u : ${yabai} -m window --toggle float && ${yabai} -m window --toggle float

          # Focus stacked windows
          # alt + shift - up : ${yabai} -m window --focus stack.prev
          # alt + shift - down : ${yabai} -m window --focus stack.next

          # Make windows larger
          # alt - h : ${yabai} -m window --resize left:-25:0
          # alt - j : ${yabai} -m window --resize bottom:0:25
          # alt - k : ${yabai} -m window --resize top:0:-25
          # alt - l : ${yabai} -m window --resize right:25:0

          # Make windows smaller
          # ctrl - h : ${yabai} -m window --resize right:-25:0
          # ctrl - j : ${yabai} -m window --resize top:0:25
          # ctrl - k : ${yabai} -m window --resize bottom:0:-25
          # ctrl - l : ${yabai} -m window --resize left:25:0

          # Move floating windows
          # alt + cmd - up : ${yabai} -m window --move rel:0:-25
          # alt + cmd - down : ${yabai} -m window --move rel:0:25
          # alt + cmd - left : ${yabai} -m window --move rel:-25:0
          # alt + cmd - right : ${yabai} -m window --move rel:25:0

          # Move windows to spaces and follow focus
          # alt + cmd - 1 : ${yabai} -m window --space 1 && ${yabai} -m space --focus 1
          # alt + cmd - 2 : ${yabai} -m window --space 2 && ${yabai} -m space --focus 2
          # alt + cmd - 3 : ${yabai} -m window --space 3 && ${yabai} -m space --focus 3
          # alt + cmd - 4 : ${yabai} -m window --space 4 && ${yabai} -m space --focus 4
          # alt + cmd - 5 : ${yabai} -m window --space 4 && ${yabai} -m space --focus 5
          # alt + cmd - n : ${yabai} -m space --create && ${yabai} -m window --space last && ${yabai} -m space --focus last

          # Toggle float
          alt + shift - f : ${yabai} -m window --toggle float

          # Focus spaces.
          alt - 1 : ${yabai} -m space --focus 1
          alt - 2 : ${yabai} -m space --focus 2
          alt - 3 : ${yabai} -m space --focus 3
          alt - 4 : ${yabai} -m space --focus 4
          alt - 5 : ${yabai} -m space --focus 5

          # Move spaces
          # ctrl + cmd - 1 : ${yabai} -m space --move 1
          # ctrl + cmd - 2 : ${yabai} -m space --move 2
          # ctrl + cmd - 3 : ${yabai} -m space --move 3
          # ctrl + cmd - 4 : ${yabai} -m space --move 4
          # ctrl + cmd - 5 : ${yabai} -m space --move 5

          # Create, mirror, balance, rotate, destroy spaces
          # alt - n : ${yabai} -m space --create && ${yabai} -m space --focus last
          # alt - y : ${yabai} -m space --mirror y-axis
          # alt - b : ${yabai} -m space --balance
          # alt - r : ${yabai} -m space --rotate 270
          # alt + shift - r : ${yabai} -m space --rotate 90
          # alt - w : ${yabai} -m space --focus prev && ${yabai} -m space recent --destroy || ${yabai} -m space --destroy
          # alt + cmd - w : ${yabai} -m window --close && ${yabai} -m space --focus prev && ${yabai} -m space recent --destroy
        ''
      );
    };
  };
}
