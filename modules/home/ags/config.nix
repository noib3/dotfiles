{ pkgs }:

{
  configDir = ./.;
  enable = pkgs.stdenv.isLinux;
}
