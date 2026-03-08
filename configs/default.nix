{
  config,
  lib,
  pkgs,
}:

{
  lazygit = import ./lazygit;
  qutebrowser = import ./qutebrowser { inherit config lib pkgs; };
  ripgrep = import ./ripgrep;
  transmission = import ./transmission;
}
