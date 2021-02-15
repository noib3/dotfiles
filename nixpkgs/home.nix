{ config, pkgs, ... }:

let
  unstable = import <nixpkgs-unstable> { config = { allowUnfree = true; }; };

in {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "noibe";
  home.homeDirectory = "/Users/noibe";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.05";

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  home.packages = with pkgs; [
    alacritty
    # auto-selfcontrol
    bash
    bat
    buku
    calcurse
    chafa
    coreutils
    duti
    entr
    exa
    fd
    ffmpeg
    findutils
    firefox
    fish
    fzf
    git
    # gnu-sed
    gotop
    jq
    lazygit
    unstable.lf
    # mas
    mediainfo
    # neovim
    nodejs
    openssh
    python39
    python39Packages.autopep8
    python39Packages.ipython
    python39Packages.pip
    redshift
    rsync
    skhd
    spacebar
    # ookla-speedtest
    # sshfs
    starship
    syncthing
    # tccutil
    terminal-notifier
    transmission
    vivid
    wget
    xmlstarlet
    yabai
  ];

  # programs.neovim = {
  #   enable = true;
  #   withPython3 = true;
  #   extraPython3Packages = (
  #     ps: with ps; [
  #       autopep8
  #       flake8
  #       isort
  #       jedi
  #       pynvim
  #     ]
  #   );
  # };
}
