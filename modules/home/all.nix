{ pkgs, ... }:

let
  inherit (pkgs.stdenv) isLinux isDarwin;
in
{
  imports = [
    ./astal
    ./dropbox
  ];

  modules = {
    astal.enable = isLinux;
    dropbox.enable = true;
  };
}
