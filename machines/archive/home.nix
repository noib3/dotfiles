{ config, lib, pkgs, ... }:

let
  unstable = import <nixos-unstable> { };
  machine = "archive";

  colorscheme = "onedark";

  dirs = {
    colorscheme = ../../colorschemes + "/${colorscheme}";
  };

  configs.bat = import (dirs.configs + /bat);

  configs.fd = import (dirs.configs + /fd) { inherit machine; };

  configs.fish = import (dirs.configs + /fish) {
    colors = import (dirs.colorscheme + /fish.nix);
  };

  configs.fzf = import (dirs.configs + /fzf) {
    colors = import (dirs.colorscheme + /fzf.nix);
  };

  configs.git = import (dirs.configs + /git);

  configs.gpg = import (dirs.configs + /gpg/gpg.nix) {
    homedir = "${config.xdg.dataHome}/gnupg";
  };

  configs.gpg-agent = import (dirs.configs + /gpg/gpg-agent.nix);

  configs.lazygit = import (dirs.configs + /lazygit);

  configs.lf = import (dirs.configs + /lf);

  configs.starship = import (dirs.configs + /starship);

  configs.vivid = import (dirs.configs + /vivid) {
    colors = import (dirs.colorscheme + /vivid.nix);
  };
in
{
  imports = [
    ../../modules/programs/fd.nix
    ../../modules/programs/vivid.nix
  ];

  home = {
    username = "noib3";
    homeDirectory = "/home/noib3";
    stateVersion = "21.03";

    packages = with pkgs; [
      chafa
      delta
      file
      gotop
      mediainfo
      neovim-nightly
      nixpkgs-fmt
      speedtest-cli
      pfetch
      vimv
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
    };
  };

  nixpkgs.overlays = [
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
    package = unstable.fish;
  } // configs.fish;

  programs.fzf = {
    enable = true;
    package = unstable.fzf;
  } // configs.fzf;

  programs.git = {
    enable = true;
  } // configs.git;

  programs.gpg = {
    enable = true;
  } // configs.gpg;

  programs.lazygit = {
    enable = true;
  } // configs.lazygit;

  programs.lf = {
    enable = true;
  } // configs.lf;

  programs.starship = {
    enable = true;
    package = unstable.starship;
  } // configs.starship;

  programs.vivid = {
    enable = true;
  } // configs.vivid;

  services.gpg-agent = {
    enable = true;
  } // configs.gpg-agent;
}
