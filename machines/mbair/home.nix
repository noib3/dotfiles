{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> { };

  theme = "onedark";
  font = "roboto-mono";

  my-python-packages = python-packages: with python-packages; [
    autopep8
    black
    flake8
    ipython
    isort
    jedi
    jupyter
    matplotlib
    numpy
  ];
  python-with-my-packages = unstable.python39.withPackages my-python-packages;

  R-with-my-packages = with pkgs; rWrapper.override {
    packages = with rPackages; [
      rmarkdown
      knitr
    ];
  };

  alacrittyConfig = {
    settings = lib.attrsets.recursiveUpdate
      (import ../../defaults/alacritty.nix {
        font = import (./fonts + "/${font}" + /alacritty.nix);
        colors = import (../../themes + "/${theme}" + /alacritty.nix);
      })
      (import ./alacritty.nix);
  };

  batConfig = import ../../defaults/bat.nix;

  fdConfig = {
    ignores =
      (import ../../defaults/fd.nix).ignores
      ++ (import ./fd.nix).ignores;
  };

  firefoxConfig = (import ../../defaults/firefox {
    font = import (./fonts + "/${font}" + /firefox.nix);
    colors = import (../../themes + "/${theme}" + /firefox.nix);
  });

  fishConfig = lib.attrsets.recursiveUpdate
    (import ../../defaults/fish.nix {
      colors = import (../../themes + "/${theme}" + /fish.nix);
    })
    (import ./fish.nix);

  fzfConfig = (import ../../defaults/fzf.nix {
    colors = import (../../themes + "/${theme}" + /fzf.nix);
  });

  gitConfig = import ../../defaults/git.nix;

  lfConfig = lib.attrsets.recursiveUpdate
    (import ../../defaults/lf.nix { })
    (import ./lf.nix);

  spacebarConfig = (import ./spacebar.nix {
    font = import (./fonts + "/${font}" + /spacebar.nix);
    colors = import (./themes + "/${theme}" + /spacebar.nix);
  });

  skhdConfig = import ./skhd.nix;

  sshConfig = import ../../defaults/ssh.nix;

  starshipConfig = import ../../defaults/starship.nix;

  vividConfig = (import ../../defaults/vivid.nix {
    colors = import (../../themes + "/${theme}" + /vivid.nix);
  });

  yabaiConfig = (import ./yabai.nix {
    colors = import (./themes + "/${theme}" + /yabai.nix);
  });
in
{
  imports = [
    ../../modules/programs/fd.nix
    ../../modules/programs/vivid.nix
    ./modules/programs/skhd.nix
    ./modules/programs/spacebar.nix
    ./modules/programs/yabai.nix
  ];

  home = {
    username = "noibe";
    homeDirectory = "/Users/noibe";
    stateVersion = "21.03";

    packages = with pkgs; [
      # auto-selfcontrol
      bash
      bitwarden-cli
      # buku # NOT SUPPORTED NEEDS OVERLAY
      # calcurse # NOT SUPPORTED NEEDS OVERLAY
      chafa
      coreutils
      direnv
      # duti
      entr
      ffmpeg
      file
      findutils
      # font-jetbrains-mono-nerd-font
      # font-roboto-mono-nerd-font
      # font-sf-mono-nerd-font
      gnused
      gotop
      jq
      lazygit
      mediainfo
      mpv
      neovim-nightly
      nixpkgs-fmt
      nodejs
      nodePackages.vim-language-server
      # nordvpn
      ookla-speedtest-cli
      openssh
      osxfuse
      pandoc
      # pdftotext
      pfetch
      python-with-my-packages
      R-with-my-packages
      # redshift
      rsync
      # selfcontrol
      skhd
      # skim
      spacebar
      # sshfs
      syncthing
      # tastyworks
      # tccutil
      terminal-notifier
      texlive.combined.scheme-full
      transmission-remote-cli
      vimv
      vivid
      wget
      xmlstarlet
      yabai
      yarn
    ];

    sessionVariables = {
      COLORTERM = "truecolor";
      EDITOR = "nvim";
      HISTFILE = "$HOME/.cache/bash/bash_history";
      MANPAGER = "nvim -c 'set ft=man' -";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      LESSHISTFILE = "$HOME/.cache/less/lesshst";
      LS_COLORS = "$(vivid generate current)";
      THEME = "${theme}";
      SECRETSDIR = "$HOME/Sync/secrets";
      SCRSHOTDIR = "$HOME/Sync/screenshots";
      SCRIPTSDIR = "$HOME/Sync/scripts";
      FZF_ONLYDIRS_COMMAND = ''
        fd --base-directory=$HOME --hidden --type=d --color=always
      '';
    };

    file = {
      "${config.xdg.configHome}/nvim" = {
        source = ../../defaults/nvim;
        recursive = true;
      };

      "${config.xdg.configHome}/tridactyl" = {
        source = ./tridactyl;
        recursive = true;
      };
    };
  };

  nixpkgs.overlays = [
    (self: super: {
      direnv = unstable.direnv;
      firefox = super.callPackage ./overlays/firefox.nix { };
      fzf = unstable.fzf;
      lf = unstable.lf;
      ookla-speedtest-cli = super.callPackage ./overlays/ookla-speedtest-cli.nix { };
      starship = unstable.starship;
      vimv = unstable.vimv;
      yabai = unstable.yabai;
    })

    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  programs.home-manager = {
    enable = true;
  };

  programs.alacritty = {
    enable = true;
  } // alacrittyConfig;

  programs.bat = {
    enable = true;
  } // batConfig;

  programs.fd = {
    enable = true;
  } // fdConfig;

  programs.firefox = {
    enable = true;
  } // firefoxConfig;

  programs.fish = {
    enable = true;
  } // fishConfig;

  programs.fzf = {
    enable = true;
  } // fzfConfig;

  programs.git = {
    enable = true;
  } // gitConfig;

  programs.lf = {
    enable = true;
  } // lfConfig;

  programs.skhd = {
    enable = true;
  } // skhdConfig;

  programs.spacebar = {
    enable = true;
  } // spacebarConfig;

  programs.ssh = {
    enable = true;
  } // sshConfig;

  programs.starship = {
    enable = true;
  } // starshipConfig;

  programs.vivid = {
    enable = true;
  } // vividConfig;

  programs.yabai = {
    enable = true;
  } // yabaiConfig;
}
