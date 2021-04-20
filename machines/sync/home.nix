{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> { };

  colorscheme = "onedark";
  colorschemes-dir = ../../colorschemes + "/${colorscheme}";

  configs = {
    bat = import ../../defaults/bat;

    direnv = import ../../defaults/direnv;

    fd =
      let
        default = import ../../defaults/fd;
      in
      import ./overrides/fd.nix { default = default; };

    fish = lib.attrsets.recursiveUpdate
      (import ../../defaults/fish {
        inherit pkgs;
        colors = import (colorschemes-dir + /fish.nix);
      })
      (import ./overrides/fish.nix);

    fzf = (import ../../defaults/fzf {
      colors = import (colorschemes-dir + /fzf.nix);
    });

    git = import ../../defaults/git;

    lf = (import ../../defaults/lf {
      inherit pkgs;
    });

    starship = import ../../defaults/starship;

    vivid = (import ../../defaults/vivid {
      colors = import (colorschemes-dir + /vivid.nix);
    });
  };
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
    };
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

  xdg.configFile = {
    "nvim" = {
      source = ../../defaults/neovim;
      recursive = true;
    };

    "nvim/lua/colorscheme/init.lua" = {
      text = (import ../../defaults/neovim/lua/colorscheme/default.nix {
        inherit lib;
        colors = import (colorschemes-dir + /neovim.nix);
      });
    };
  };

  programs.home-manager = {
    enable = true;
  };

  programs.bat = {
    enable = true;
  } // configs.bat;

  programs.fd = {
    enable = true;
  } // configs.fd;

  programs.fish = {
    enable = true;
  } // configs.fish;

  programs.fzf = {
    enable = true;
  } // configs.fzf;

  programs.git = {
    enable = true;
  } // configs.git;

  programs.lf = {
    enable = true;
  } // configs.lf;

  programs.starship = {
    enable = true;
  } // configs.starship;

  programs.vivid = {
    enable = true;
  } // configs.vivid;
}
