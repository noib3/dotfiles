{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.zed;
in
{
  options.modules.zed = {
    enable = mkEnableOption "Zed";
  };

  config = mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
      extensions = [ "nix" ];
      mutableUserKeymaps = false;
      mutableUserSettings = false;
      themes = import ./themes;
      userKeymaps = import ./keymaps.nix;
      userSettings = import ./settings.nix { inherit lib pkgs config; };
    };
  };
}
