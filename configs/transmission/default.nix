let
  pkgs = import <nixpkgs> { };

  notify-done = pkgs.writeShellScriptBin "notify-done"
    (import ./notify-done.sh.nix);
in
{
  user = "noib3";
  settings = {
    download-dir = "/home/noib3/Downloads";
    script-torrent-done-enabled = true;
    script-torrent-done-filename = "${notify-done}/bin/notify-done";
  };
}
