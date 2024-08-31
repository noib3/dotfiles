{ config }:

{
  configDotToml = ''
    [build]
    target-dir = "${config.xdg.cacheHome}/cargo"
  '';
}
