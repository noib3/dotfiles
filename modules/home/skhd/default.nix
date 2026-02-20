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

          # Focus spaces.
          alt - 1 : ${yabai} -m space --focus 1
          alt - 2 : ${yabai} -m space --focus 2
          alt - 3 : ${yabai} -m space --focus 3
          alt - 4 : ${yabai} -m space --focus 4
          alt - 5 : ${yabai} -m space --focus 5
        ''
      );
    };
  };
}
