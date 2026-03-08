{
  config,
  lib,
  pkgs,
}:

{
  qutebrowser = import ./qutebrowser { inherit config lib pkgs; };
}
