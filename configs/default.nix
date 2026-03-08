{
  config,
  lib,
  pkgs,
}:

{
  kanshi = import ./kanshi { inherit pkgs; };
  lazygit = import ./lazygit;
  mpris-proxy = import ./mpris-proxy { inherit pkgs; };
  qutebrowser = import ./qutebrowser { inherit config lib pkgs; };
  ripgrep = import ./ripgrep;
  skhd = import ./skhd { inherit pkgs; };
  transmission = import ./transmission;
  wlsunset = import ./wlsunset { inherit pkgs; };
  zathura = import ./zathura { inherit config pkgs; };
}
