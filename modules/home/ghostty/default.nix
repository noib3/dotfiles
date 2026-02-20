{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  inherit (pkgs.stdenv) isDarwin isLinux;
  cfg = config.modules.ghostty;
  package = if isDarwin then pkgs.brewCasks.ghostty else pkgs.ghostty;
in
{
  options.modules.ghostty = {
    enable = mkEnableOption "Ghostty";
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      inherit package;
      enable = true;
      enableFishIntegration = config.programs.fish.enable;
      settings = {
        adjust-cursor-thickness = "200%";
        auto-update = "off";
        cursor-style = "bar";
        cursor-style-blink = false;
        keybind = import ./keybinds.nix { inherit lib isDarwin isLinux; };
        quit-after-last-window-closed = true;
        # Without this the cursor will still blink, even if cursor-style-blink
        # is set to false. See [1] for more infos.
        #
        # [1]: https://github.com/ghostty-org/ghostty/discussions/2812
        shell-integration-features = "no-cursor";
        window-padding-x = 10;
        window-padding-y = 5;
        unfocused-split-opacity = 1.0;
      }
      // lib.attrsets.optionalAttrs isLinux {
        mouse-scroll-multiplier = 1.25;
      }
      // (import ./colors.nix { inherit config; })
      // (import ./font.nix { inherit config lib isDarwin; });
    };

    modules.terminals.ghostty = {
      enabled = true;
      inherit package;
      launchCommand = "${lib.getExe package} --working-directory=${config.home.homeDirectory}";
    };
  };
}
