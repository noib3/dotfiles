{ pkgs, ... }:

let
  inherit (pkgs.stdenv) isLinux isDarwin;
in
{
  imports = [
    ./ags
    ./dropbox
  ];

  modules = {
    ags.enable = isLinux;
    dropbox.enable = isLinux;
  };
}
