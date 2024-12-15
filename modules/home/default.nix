{ pkgs, ... }:

let
  inherit (pkgs.stdenv) isLinux isDarwin;
in
{
  imports = [
    ./astal
    ./dropbox
    ./lib
    ./neovim
    ./scripts
    ./ssh
  ];

  modules = {
    astal.enable = isLinux;
    dropbox.enable = true;
    neovim.enable = true;
    ssh.enable = true;
  };
}
