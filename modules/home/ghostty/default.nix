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
in
{
  options.modules.ghostty = {
    enable = mkEnableOption "Ghostty";
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      package = if isDarwin then pkgs.brewCasks.ghostty else pkgs.ghostty;
      enableFishIntegration = config.programs.fish.enable;
      settings = {
        adjust-cursor-thickness = "200%";
        cursor-style = "bar";
        cursor-style-blink = false;
        keybind = import ./keybinds.nix { inherit lib isDarwin isLinux; };
        # Without this the cursor will still blink, even if cursor-style-blink
        # is set to false. See [1] for more infos.
        #
        # [1]: https://github.com/ghostty-org/ghostty/discussions/2812
        shell-integration-features = "no-cursor";
        window-padding-x = 10;
        window-padding-y = 5;
      }
      // (import ./colors.nix { inherit config; })
      // (import ./font.nix { inherit config isDarwin; });
    };
  };
}
