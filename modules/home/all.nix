{ pkgs, ... }:

let
  inherit (pkgs.stdenv) isLinux isDarwin;
in
{
  imports = [
    ./astal
    ./dropbox
    ./lib
    ./scripts
    ./ssh
  ];

  modules = {
    astal.enable = isLinux;
    dropbox.enable = true;
    ssh.enable = true;
  };
}
