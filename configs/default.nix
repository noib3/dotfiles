{
  config,
  lib,
  pkgs,
}:

{
  home-manager = import ./home-manager;
  kanshi = import ./kanshi { inherit pkgs; };
  lazygit = import ./lazygit;
  lf = import ./lf { inherit lib pkgs; };
  mpris-proxy = import ./mpris-proxy { inherit pkgs; };
  mpv = import ./mpv { inherit pkgs; };
  nix-index = import ./nix-index;
  qutebrowser = import ./qutebrowser { inherit config lib pkgs; };
  ripgrep = import ./ripgrep;
  skhd = import ./skhd { inherit pkgs; };
  transmission = import ./transmission;
  wlsunset = import ./wlsunset { inherit pkgs; };
  zathura = import ./zathura { inherit config pkgs; };
}
