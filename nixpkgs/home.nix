{ config, lib, pkgs, ... }:

let
  unstable = import <nixpkgs-unstable> { config = { allowUnfree = true; }; };

  machine = "mbair";
  theme   = "onedark";
  font    = "RobotoMono";

  alacrittyConfig = lib.attrsets.recursiveUpdate
    (import ./defaults/alacritty.nix { font = font; theme = theme; })
    (import (./machines + "/${machine}" + /alacritty.nix));

  fishConfig = lib.attrsets.recursiveUpdate
    (import ./defaults/fish.nix { pkgs = pkgs; theme = theme; })
    (import (./machines + "/${machine}" + /fish.nix) );

  lfConfig = lib.attrsets.recursiveUpdate
    (import ./defaults/lf.nix { pkgs = pkgs; })
    (import (./machines + "/${machine}" + /lf.nix) );

  batConfig      = import ./defaults/bat.nix;
  fzfConfig      = import ./defaults/fzf.nix { theme = theme; };
  gitConfig      = import ./defaults/git.nix;
  starshipConfig = import ./defaults/starship.nix;

in {
  home = {
    username      = "noibe";
    homeDirectory = "/Users/noibe";
    stateVersion  = "21.03";

    packages = with pkgs; [
      # auto-selfcontrol
      bash
      buku
      calcurse
      chafa
      coreutils
      direnv
      duti
      entr
      fd
      ffmpeg
      findutils
      # firefox
      # font-jetbrains-mono-nerd-font
      # font-roboto-mono-nerd-font
      # font-sf-mono-nerd-font
      gnused
      gotop
      jq
      lazygit
      # logitech-options
      # mactex-no-gui
      # mas
      # mysides
      mediainfo
      mpv
      neovim-nightly
      # nodejs
      # nordvpn
      openssh
      osxfuse
      # pdftotext
      pfetch
      (python39.withPackages(
        ps: with ps; [
          autopep8
          black
          flake8
          ipython
          isort
          jedi
        ]
      ))
      # redshift
      rsync
      # selfcontrol
      # skhd
      # skim
      # spacebar
      # ookla-speedtest
      # sshfs
      # syncthing
      # tastyworks
      # tccutil
      terminal-notifier
      transmission-remote-cli
      vivid
      wget
      xmlstarlet
      # yabai
    ];

    sessionVariables = {
      COLORTERM    = "truecolor";
      COLORSCHEME  = "${theme}";
      EDITOR       = "nvim";
      HISTFILE     = "$HOME/.cache/bash/bash_history";
      MANPAGER     = "nvim -c 'set ft=man' -";
      LANG         = "en_US.UTF-8";
      LC_ALL       = "en_US.UTF-8";
      LESSHISTFILE = "$HOME/.cache/less/lesshst";
      LS_COLORS    = "$(vivid generate ${theme})";
      PRIVATEDIR   = "$HOME/Sync/private";
      SCRSHOTDIR   = "$HOME/Sync/screenshots";
      SCRIPTSDIR   = "$HOME/Sync/scripts";
      FZF_ONLYDIRS_COMMAND = ''
        fd --base-directory=$HOME --hidden --type=d --color=always
      '';
    };
  };

  nixpkgs = {
    config = {
      allowUnsupportedSystem = true;
    };

    overlays = [
      (self: super: {
        direnv   = unstable.direnv;
        fzf      = unstable.fzf;
        lf       = unstable.lf;
        python39 = unstable.python39;
        starship = unstable.starship;
      })
      (import (builtins.fetchTarball {
        url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
      }))
    ];
  };

  programs.home-manager = {
    enable = true;
  };

  programs.alacritty = {
    enable = true;
    settings = alacrittyConfig;
  };

  programs.bat = {
    enable = true;
    config = batConfig;
  };

  programs.fish = lib.attrsets.recursiveUpdate fishConfig {
    enable = true;
  };

  programs.fzf = lib.attrsets.recursiveUpdate fzfConfig {
    enable = true;
  };

  programs.git = lib.attrsets.recursiveUpdate gitConfig {
    enable = true;
  };

  programs.lf = lib.attrsets.recursiveUpdate lfConfig {
    enable = true;
  };

  programs.starship = {
    enable = true;
    settings = starshipConfig;
  };
}
