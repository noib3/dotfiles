{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> { };

  theme = "onedark";

  my-python-packages = python-packages: with python-packages; [
    ipython
  ];
  python-with-my-packages = unstable.python39.withPackages my-python-packages;

  batConfig = import ../../defaults/bat.nix;

  fdConfig = {
    ignores =
      (import ../../defaults/fd.nix).ignores
      ++ (import ./fd.nix).ignores;
  };

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

  starshipConfig = import ../../defaults/starship.nix;

  vividConfig = (import ../../defaults/vivid.nix {
    colors = import (../../themes + "/${theme}" + /vivid.nix);
  });
in
{
  imports = [
    ../../modules/programs/fd.nix
    ../../modules/programs/vivid.nix
  ];

  home = {
    username = "nix";
    homeDirectory = "/home/nix";
    stateVersion = "21.03";

    packages = with pkgs; [
      bat
      chafa
      direnv
      fd
      file
      fish
      git
      gotop
      lazygit
      mediainfo
      neovim-nightly
      nixpkgs-fmt
      nodejs
      nodePackages.vim-language-server
      ookla-speedtest-cli
      pfetch
      python-with-my-packages
      vimv
      vivid
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
      FZF_ONLYDIRS_COMMAND = ''
        fd --base-directory=$HOME --hidden --type=d --color=always
      '';
    };

    file = {
      "${config.xdg.configHome}/nvim" = {
        source = ../../defaults/nvim;
        recursive = true;
      };
    };
  };

  nixpkgs.overlays = [
    (self: super: {
      direnv = unstable.direnv;
      fzf = unstable.fzf;
      lf = unstable.lf;
      ookla-speedtest-cli = super.callPackage ./overlays/ookla-speedtest-cli.nix { };
      starship = unstable.starship;
      vimv = unstable.vimv;
    })

    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  programs.home-manager = {
    enable = true;
  };

  programs.bat = {
    enable = true;
  } // batConfig;

  programs.fd = {
    enable = true;
  } // fdConfig;

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

  programs.starship = {
    enable = true;
  } // starshipConfig;

  programs.vivid = {
    enable = true;
  } // vividConfig;
}
