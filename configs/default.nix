{
  config,
  lib,
  pkgs,
}:

{
  alacritty = import ./alacritty { inherit config lib pkgs; };
  bat = import ./bat;
  bspwm = import ./bspwm;
  calcurse = import ./calcurse;
  direnv = import ./direnv;
  dmenu = import ./dmenu;
  dunst = import ./dunst;
  fd = import ./fd { inherit lib pkgs; };
  fish = import ./fish { inherit config pkgs lib; };
  fusuma = import ./fusuma { inherit pkgs; };
  fuzzel = import ./fuzzel { inherit pkgs; };
  fzf = import ./fzf { inherit config pkgs; };
  git = import ./git { inherit config; };
  gpg = import ./gpg;
  gpg-agent = import ./gpg-agent { inherit pkgs; };
  grub = import ./grub;
  home-manager = import ./home-manager;
  hyprland = import ./hyprland { inherit pkgs; };
  kanshi = import ./kanshi { inherit config pkgs; };
  lazygit = import ./lazygit;
  lf = import ./lf { inherit lib pkgs; };
  mpris-proxy = import ./mpris-proxy { inherit pkgs; };
  mpv = import ./mpv { inherit pkgs; };
  nix-index = import ./nix-index;
  picom = import ./picom;
  polybar = import ./polybar;
  qutebrowser = import ./qutebrowser { inherit config lib pkgs; };
  ripgrep = import ./ripgrep;
  skhd = import ./skhd { inherit pkgs; };
  ssh-agent = import ./ssh-agent { inherit pkgs; };
  starship = import ./starship { inherit lib; };
  sxhkd = import ./sxhkd;
  transmission = import ./transmission;
  udiskie = import ./udiskie { inherit pkgs; };
  vivid = import ./vivid { inherit config lib; };
  wlsunset = import ./wlsunset { inherit pkgs; };
  yabai = import ./yabai { inherit pkgs; };
  zathura = import ./zathura { inherit config pkgs; };
}
