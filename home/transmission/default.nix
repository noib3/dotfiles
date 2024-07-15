{ pkgs
, username
, homeDirectory
}:

let
  notify-done = pkgs.writeShellScriptBin "notify-done"
    (import ./notify-done.sh.nix { inherit pkgs; });
in
{
  user = username;
  settings = {
    download-dir = "${homeDirectory}/Downloads";
    script-torrent-done-enabled = true;
    script-torrent-done-filename = "${notify-done}/bin/notify-done";
  };
}
