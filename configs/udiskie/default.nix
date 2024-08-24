{ pkgs }:

{
  enable = pkgs.stdenv.isLinux;
  automount = true;
  notify = true;
  tray = "never";
}
