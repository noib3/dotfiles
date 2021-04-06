{ config, pkgs, lib, ... }:
let
  unstable = import <nixos-unstable> { };

  font = "roboto-mono";
  colorscheme = "onedark";

  fonts-dir = ./fonts + "/${font}";
  colorschemes-dir = ../../colorschemes + "/${colorscheme}";

  sync-dir = config.home.homeDirectory + "/Sync";
  secrets-dir = sync-dir + "/secrets";

  email-accounts = import ../../defaults/email;

  R-with-my-packages = with pkgs; rWrapper.override {
    packages = with rPackages; [
      rmarkdown
      knitr
    ];
  };

  alacrittyConfig =
    let
      default =
        (import ../../defaults/alacritty {
          inherit pkgs;
          font = import (fonts-dir + /alacritty.nix);
          colors = import (colorschemes-dir + /alacritty.nix);
        });
    in
    lib.attrsets.recursiveUpdate
      default
      (import ./overrides/alacritty.nix { default = default; });

  batConfig = import ../../defaults/bat;

  direnvConfig = import ../../defaults/direnv;

  fdConfig =
    let
      default = import ../../defaults/fd;
    in
    import ./overrides/fd.nix { default = default; };

  firefoxConfig = (import ../../defaults/firefox {
    font = import (fonts-dir + /firefox.nix);
    colors = import (colorschemes-dir + /firefox.nix);
  });

  fishConfig = lib.attrsets.recursiveUpdate
    (import ../../defaults/fish {
      colors = import (colorschemes-dir + /fish.nix);
    })
    (import ./overrides/fish.nix);

  fzfConfig = (import ../../defaults/fzf {
    colors = import (colorschemes-dir + /fzf.nix);
  });

  gitConfig = lib.attrsets.recursiveUpdate
    (import ../../defaults/git)
    (import ./overrides/git.nix);

  lfConfig = lib.attrsets.recursiveUpdate
    (import ../../defaults/lf { })
    (import ./overrides/lf.nix);

  mpvConfig = import ../../defaults/mpv;

  neomuttConfig = import ../../defaults/neomutt;

  spacebarConfig = (import ../../defaults/spacebar {
    font = import (fonts-dir + /spacebar.nix);
    colors = import (colorschemes-dir + /spacebar.nix);
  });

  skhdConfig = import ../../defaults/skhd;

  sshConfig = import ../../defaults/ssh;

  starshipConfig = import ../../defaults/starship;

  tridactylConfig = (import ../../defaults/tridactyl {
    font = import (fonts-dir + /tridactyl.nix);
    colors = import (colorschemes-dir + /tridactyl.nix);
  });

  vividConfig = (import ../../defaults/vivid {
    colors = import (colorschemes-dir + /vivid.nix);
  });

  yabaiConfig = (import ../../defaults/yabai {
    colors = import (colorschemes-dir + /yabai.nix);
  });
in
{
  imports = [
    ../../modules/programs/fd.nix
    ../../modules/programs/skhd.nix
    ../../modules/programs/spacebar.nix
    ../../modules/programs/tridactyl.nix
    ../../modules/programs/vivid.nix
    ../../modules/programs/yabai.nix
  ];

  accounts.email.accounts = email-accounts;

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
      doctl
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
      nodePackages.vscode-html-languageserver-bin
      nodePackages.vim-language-server
      # nordvpn
      ookla-speedtest-cli
      openssh
      osxfuse
      pandoc
      # pdftotext
      pfetch
      (python39.withPackages (
        ps: with ps; [
          autopep8
          black
          flake8
          ipython
          isort
          jedi
          jupyter
          matplotlib
          numpy
        ]
      ))
      R-with-my-packages
      # redshift
      rsync
      # selfcontrol
      # skim
      # sshfs
      syncthing
      # tastyworks
      # tccutil
      terminal-notifier
      texlive.combined.scheme-full
      transmission-remote-cli
      vimv
      wget
      xmlstarlet
      yarn
    ];

    sessionVariables = {
      COLORTERM = "truecolor";
      EDITOR = "nvim";
      HISTFILE = "${config.home.homeDirectory}/.cache/bash/bash_history";
      MANPAGER = "nvim -c 'set ft=man' -";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      LESSHISTFILE = "${config.home.homeDirectory}/.cache/less/lesshst";
      LS_COLORS = "$(vivid generate current)";
      SECRETSDIR = "${secrets-dir}";
    };

    file = {
      ".ssh" = {
        source = "${secrets-dir}/ssh-keys";
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
      python39 = unstable.python39;
      starship = unstable.starship;
      vimv = unstable.vimv;
      yabai = unstable.yabai;
    })

    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  xdg.configFile."nvim" = {
    source = ../../defaults/neovim;
    recursive = true;
  };

  xdg.configFile."nvim/lua/colorscheme/init.lua" = {
    text = (import ../../defaults/neovim/lua/colorscheme/default.nix {
      inherit lib;
      colors = import (colorschemes-dir + /neovim.nix);
    });
  };

  programs.home-manager = {
    enable = true;
  };

  programs.alacritty = {
    enable = true;
  } // alacrittyConfig;

  programs.bat = {
    enable = true;
  } // batConfig;

  programs.direnv = {
    enable = true;
  } // direnvConfig;

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

  programs.mpv = {
    enable = true;
  } // mpvConfig;

  programs.neomutt = {
    enable = true;
  } // neomuttConfig;

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

  programs.tridactyl = {
    enable = true;
  } // tridactylConfig;

  programs.vivid = {
    enable = true;
  } // vividConfig;

  programs.yabai = {
    enable = true;
  } // yabaiConfig;
}
