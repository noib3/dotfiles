{ pkgs, ... }:

let
  inherit (pkgs.stdenv) isLinux isDarwin;
in
{
  imports = [
    ./astal
    ./dropbox
    ./ssh
  ];

  modules = {
    astal.enable = isLinux;
    dropbox.enable = true;
    ssh.enable = true;
  };
}
