{ pkgs }:

{
  defaultCacheTtl = 604800;
  defaultCacheTtlSsh = 604800;
  maxCacheTtl = 604800;
  maxCacheTtlSsh = 604800;
  pinentryPackage = pkgs.pinentry-qt;
}
