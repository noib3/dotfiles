{ config, lib, pkgs, ... }:

let
  unstable = import <nixpkgs-unstable> { config = { allowUnfree = true; }; };

  theme = "onedark";
  font  = "RobotoMono";

  alacrittyConfig = {
    settings = lib.attrsets.recursiveUpdate
      (import ../../defaults/alacritty.nix { font = font; theme = theme; })
      (import ./alacritty.nix);
  };

  fdConfig = {
    ignores =
      (import ../../defaults/fd.nix).ignores ++ (import ./fd.nix).ignores ;
  };

  fishConfig = lib.attrsets.recursiveUpdate
    (import ../../defaults/fish.nix { pkgs = pkgs; theme = theme; })
    (import ./fish.nix );

  lfConfig = lib.attrsets.recursiveUpdate
    (import ../../defaults/lf.nix { pkgs = pkgs; })
    (import ./lf.nix );

  batConfig      = import ../../defaults/bat.nix;
  fzfConfig      = import ../../defaults/fzf.nix { theme = theme; };
  gitConfig      = import ../../defaults/git.nix;
  starshipConfig = import ../../defaults/starship.nix;
  vividConfig    = import ../../defaults/vivid.nix { theme = theme; };

in {
  imports = [
    ../../modules/programs/fd.nix
    ../../modules/programs/vivid.nix
  ];

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
      # fd
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
      # vimv
      vivid
      wget
      xmlstarlet
      yabai
      yarn
    ];

    sessionVariables = {
      COLORTERM    = "truecolor";
      EDITOR       = "nvim";
      HISTFILE     = "$HOME/.cache/bash/bash_history";
      MANPAGER     = "nvim -c 'set ft=man' -";
      LANG         = "en_US.UTF-8";
      LC_ALL       = "en_US.UTF-8";
      LESSHISTFILE = "$HOME/.cache/less/lesshst";
      LS_COLORS    = "$(vivid generate ${theme})";
      THEME        = "${theme}";
      SECRETSDIR   = "$HOME/Sync/secrets";
      SCRSHOTDIR   = "$HOME/Sync/screenshots";
      SCRIPTSDIR   = "$HOME/Sync/scripts";
      FZF_ONLYDIRS_COMMAND = ''
        fd --base-directory=$HOME --hidden --type=d --color=always
      '';
    };

    file = {
      "${config.xdg.configHome}/nvim" = {
        source    = ../../defaults/nvim;
        recursive = true;
      };

      "${config.xdg.configHome}/firefox" = {
        source    = ./firefox;
        recursive = true;
      };

      "${config.xdg.configHome}/skhd" = {
        source    = ./skhd;
        recursive = true;
      };

      "${config.xdg.configHome}/spacebar" = {
        source    = ./spacebar;
        recursive = true;
      };

      "${config.xdg.configHome}/tridactyl" = {
        source    = ./tridactyl;
        recursive = true;
      };

      "${config.xdg.configHome}/yabai" = {
        source    = ./yabai;
        recursive = true;
      };
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
        vimv     = unstable.vimv;
      })
      (import (builtins.fetchTarball {
        url =
          https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
      }))
    ];
  };

  programs.home-manager = { enable = true; };

  programs.alacritty = alacrittyConfig // { enable = true; };
  programs.bat       = batConfig       // { enable = true; };
  programs.fd        = fdConfig        // { enable = true; };
  programs.fish      = fishConfig      // { enable = true; };
  programs.fzf       = fzfConfig       // { enable = true; };
  programs.git       = gitConfig       // { enable = true; };
  programs.lf        = lfConfig        // { enable = true; };
  programs.starship  = starshipConfig  // { enable = true; };
  # programs.vivid     = vividConfig     // { enable = true; };
}
