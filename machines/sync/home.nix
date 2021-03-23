{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> { };

  theme = "onedark";

  my-python-packages = python-packages: with python-packages; [
    ipython
  ];
  python-with-my-packages = unstable.python39.withPackages my-python-packages;

  batConfig = import ../../defaults/bat;

  fdConfig = {
    ignores =
      (import ../../defaults/fd).ignores
      ++ (import ./fd.nix).ignores;
  };

  fishConfig = lib.attrsets.recursiveUpdate
    (import ../../defaults/fish {
      colors = import (../../themes + "/${theme}" + /fish.nix);
    })
    (import ./fish.nix);

  fzfConfig = (import ../../defaults/fzf {
    colors = import (../../themes + "/${theme}" + /fzf.nix);
  });

  gitConfig = import ../../defaults/git;

  lfConfig = import ../../defaults/lf { };

  starshipConfig = import ../../defaults/starship;

  vividConfig = (import ../../defaults/vivid {
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
      chafa
      file
      gotop
      lazygit
      mediainfo
      neovim-nightly
      nixpkgs-fmt
      ookla-speedtest-cli
      pfetch
      python-with-my-packages
      vimv
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
  };

  xdg.configFile."nvim" = {
    source = ../../defaults/nvim;
    recursive = true;
  };

  nixpkgs.overlays = [
    (self: super: {
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
