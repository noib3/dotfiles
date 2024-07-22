{ pkgs }:

let 
  seven_days = 604800;
in
{
  defaultCacheTtl = seven_days;
  maxCacheTtl = seven_days;
  defaultCacheTtlSsh = seven_days;
  maxCacheTtlSsh = seven_days;
  pinentryPackage = pkgs.pinentry-qt;
}
