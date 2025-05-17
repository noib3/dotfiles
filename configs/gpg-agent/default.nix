{ pkgs }:

let
  seven_days = 604800;
in
{
  enable = pkgs.stdenv.isLinux;
  defaultCacheTtl = seven_days;
  maxCacheTtl = seven_days;
  defaultCacheTtlSsh = seven_days;
  maxCacheTtlSsh = seven_days;
  pinentry.package = pkgs.pinentry-qt;
}
