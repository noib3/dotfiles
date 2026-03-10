{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.transmission;
  notify-done = pkgs.writeShellScriptBin "notify-done" (
    import ./notify-done.sh.nix { inherit pkgs; }
  );
  username = config.modules.desktop.username;
in
{
  options.modules.transmission = {
    enable = mkEnableOption "Transmission";
  };

  config = mkIf cfg.enable {
    services.transmission = {
      enable = true;
      user = username;
      settings = {
        download-dir = "/home/${username}/Downloads";
        script-torrent-done-enabled = true;
        script-torrent-done-filename = lib.getExe notify-done;
      };
    };
  };
}
