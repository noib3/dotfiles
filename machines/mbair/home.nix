{ config, lib, pkgs, ... }:

let
  unstable = import <nixos-unstable> { };
  machine = "mbair";

  colorscheme = "onedark";
  font = "roboto-mono";

  dirs = {
    colorscheme = ../../colorschemes + "/${colorscheme}";
    configs = ../../configs;
    font = ../../fonts + "/${font}";
    sync = config.home.homeDirectory + "/sync";
  };

  configs.alacritty = import (dirs.configs + /alacritty) {
    shell = {
      program = "${unstable.fish}/bin/fish";
      args = [ "--interactive" ];
    };
    font = import (dirs.font + /alacritty.nix) {
      inherit machine;
    };
    colors = import (dirs.colorscheme + /alacritty.nix);
  };

  configs.bat = import (dirs.configs + /bat);

  configs.fd = import (dirs.configs + /fd) { inherit machine; };

  configs.firefox = import (dirs.configs + /firefox) {
    font = import (dirs.font + /firefox.nix) {
      inherit machine;
    };
    colors = import (dirs.colorscheme + /firefox.nix);
  };

  configs.fish = import (dirs.configs + /fish) {
    colors = import (dirs.colorscheme + /fish.nix);
  };

  configs.fzf = import (dirs.configs + /fzf) {
    colors = import (dirs.colorscheme + /fzf.nix);
  };

  configs.git = import (dirs.configs + /git);

  configs.lf = import (dirs.configs + /lf);

  configs.mpv = import (dirs.configs + /mpv);

  configs.spacebar = import (dirs.configs + /spacebar) {
    font = import (dirs.font + /spacebar.nix);
    colors = import (dirs.colorscheme + /spacebar.nix);
  };

  configs.skhd = import (dirs.configs + /skhd);

  configs.ssh = import (dirs.configs + /ssh);

  configs.starship = import (dirs.configs + /starship);

  configs.tridactyl = import (dirs.configs + /tridactyl) {
    font = import (dirs.font + /tridactyl.nix);
    colors = import (dirs.colorscheme + /tridactyl.nix);
  };

  configs.vivid = import (dirs.configs + /vivid) {
    colors = import (dirs.colorscheme + /vivid.nix);
  };

  configs.yabai = import (dirs.configs + /yabai) {
    colors = import (dirs.colorscheme + /yabai.nix);
  };
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

  home = {
    username = "noibe";
    homeDirectory = "/Users/noibe";
    stateVersion = "21.03";

    packages = with pkgs; [
      bash
      bitwarden-cli
      # calcurse
      chafa
      coreutils
      delta
      # duti
      entr
      ffmpegthumbnailer
      file
      findutils
      gnused
      gotop
      jq
      mediainfo
      neovim-nightly
      (nerdfonts.override {
        fonts = [
          "FiraCode"
          "JetBrainsMono"
          "RobotoMono"
        ];
      })
      nixpkgs-fmt
      nodejs
      nodePackages.vscode-html-languageserver-bin
      nodePackages.vim-language-server
      # nordvpn
      speedtest-cli
      openssh
      osxfuse
      pandoc
      # pdftotext
      pfetch
      (python39.withPackages (
        ps: with ps; [
          autopep8
          ipython
          isort
          pynvim
        ]
      ))
      # redshift
      # selfcontrol
      # skim
      # sshfs
      # tastyworks
      # tccutil
      terminal-notifier
      unstable.texlive.combined.scheme-full
      transmission-remote-cli
      vimv
      wget
      xmlstarlet
      yarn
    ];

    sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim -c 'set ft=man' -";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      COLORTERM = "truecolor";
      LS_COLORS = "$(vivid generate current)";
      LF_ICONS = (builtins.readFile (dirs.configs + /lf/LF_ICONS));
      HISTFILE = "${config.xdg.cacheHome}/bash/bash_history";
      LESSHISTFILE = "${config.xdg.cacheHome}/less/lesshst";
      SYNCDIR =
        if lib.pathExists dirs.sync then
          builtins.toString dirs.sync
        else
          "";
    };
  };

  nixpkgs.overlays = [
    (self: super: {
      firefox = super.callPackage ./overlays/firefox.nix { };
    })

    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  xdg.configFile = {
    "nvim" = {
      source = (dirs.configs + /neovim);
      recursive = true;
    };

    "nvim/lua/colorscheme/init.lua" = {
      text = import (dirs.configs + /neovim/lua/colorscheme/init.lua.nix) {
        colors = import (dirs.colorscheme + /neovim.nix);
      };
    };

    "nvim/lua/plugins/config/lsp/sumneko-paths.lua" = {
      text = import (dirs.configs + /neovim/lua/plugins/config/lsp/sumneko-paths.lua.nix);
    };

    "redshift/hooks/notify-change" = {
      text = import (dirs.configs + /redshift/notify-change.sh.nix);
      executable = true;
    };
  };

  programs.home-manager = {
    enable = true;
  };

  programs.alacritty = {
    enable = true;
  } // configs.alacritty;

  programs.bat = {
    enable = true;
  } // configs.bat;

  programs.fd = {
    enable = true;
  } // configs.fd;

  programs.firefox = {
    enable = true;
  } // configs.firefox;

  programs.fish = {
    enable = true;
    package = unstable.fish;
  } // configs.fish;

  programs.fzf = {
    enable = true;
    package = unstable.fzf;
  } // configs.fzf;

  programs.git = {
    enable = true;
  } // configs.git;

  programs.lf = {
    enable = true;
  } // configs.lf;

  programs.mpv = {
    enable = true;
  } // configs.mpv;

  programs.skhd = {
    enable = true;
  } // configs.skhd;

  programs.spacebar = {
    enable = true;
  } // configs.spacebar;

  programs.ssh = {
    enable = true;
  } // configs.ssh;

  programs.starship = {
    enable = true;
  } // configs.starship;

  programs.tridactyl = {
    enable = true;
  } // configs.tridactyl;

  programs.vivid = {
    enable = true;
  } // configs.vivid;

  programs.yabai = {
    enable = true;
  } // configs.yabai;
}
