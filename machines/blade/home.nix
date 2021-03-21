{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> { };

  theme = "onedark";
  font = "roboto-mono";

  my-python-packages = python-packages: with python-packages; [
    ipython
  ];
  python-with-my-packages = unstable.python39.withPackages my-python-packages;

  alacrittyConfig = lib.attrsets.recursiveUpdate
    (import ../../defaults/alacritty {
      font = import (./fonts + "/${font}" + /alacritty.nix);
      colors = import (../../themes + "/${theme}" + /alacritty.nix);
    })
    (import ./alacritty.nix);

  batConfig = import ../../defaults/bat;

  bspwmConfig = (import ../../defaults/bspwm {
    colors = import (../../themes + "/${theme}" + /bspwm.nix);
    theme = theme;
  });

  direnvConfig = import ../../defaults/direnv;

  fdConfig = {
    ignores =
      (import ../../defaults/fd).ignores
      ++ (import ./fd.nix).ignores;
  };

  firefoxConfig = (import ../../defaults/firefox {
    font = import (./fonts + "/${font}" + /firefox.nix);
    colors = import (../../themes + "/${theme}" + /firefox.nix);
  });

  fishConfig = lib.attrsets.recursiveUpdate
    (import ../../defaults/fish {
      colors = import (../../themes + "/${theme}" + /fish.nix);
    })
    (import ./fish.nix);

  fzfConfig = (import ../../defaults/fzf {
    colors = import (../../themes + "/${theme}" + /fzf.nix);
  });

  gitConfig = lib.attrsets.recursiveUpdate
    (import ../../defaults/git)
    (import ./git.nix);

  lfConfig = lib.attrsets.recursiveUpdate
    (import ../../defaults/lf { })
    (import ./lf.nix { });

  picomConfig = import ../../defaults/picom;

  polybarConfig = (import ../../defaults/polybar {
    font = import (./fonts + "/${font}" + /polybar.nix);
    colors = import (../../themes + "/${theme}" + /polybar.nix);
  });

  qutebrowserConfig = (import ../../defaults/qutebrowser {
    font = import (./fonts + "/${font}" + /qutebrowser.nix);
    colors = import (../../themes + "/${theme}" + /qutebrowser.nix);
  });

  rofiConfig = (import ../../defaults/rofi);

  starshipConfig = import ../../defaults/starship;

  sxhkdConfig = import ../../defaults/sxhkd;

  sshConfig = import ../../defaults/ssh;

  tridactylConfig = (import ../../defaults/tridactyl {
    font = import (./fonts + "/${font}" + /tridactyl.nix);
    colors = import (../../themes + "/${theme}" + /tridactyl.nix);
  });

  vividConfig = (import ../../defaults/vivid {
    colors = import (../../themes + "/${theme}" + /vivid.nix);
  });

  zathuraConfig = (import ../../defaults/zathura {
    font = import (./fonts + "/${font}" + /zathura.nix);
    colors = import (../../themes + "/${theme}" + /zathura.nix);
  });
in
{
  imports = [
    ../../modules/programs/fd.nix
    ../../modules/programs/tridactyl.nix
    ../../modules/programs/vivid.nix
  ];

  home = {
    username = "noib3";
    homeDirectory = "/home/noib3";
    stateVersion = "21.03";

    file = {
      "/home/noib3/.ssh" = {
        source = "/home/noib3/Sync/secrets/ssh-keys";
        recursive = true;
      };
    };

    packages = with pkgs; [
      bat
      calcurse
      chafa
      fd
      file
      fish
      feh
      gotop
      graphicsmagick-imagemagick-compat
      lazygit
      mediainfo
      neovim-nightly
      (nerdfonts.override {
        fonts = [
          "JetBrainsMono"
          "RobotoMono"
        ];
      })
      nixpkgs-fmt
      nodejs
      noto-fonts-emoji
      ookla-speedtest-cli
      pfetch
      python-with-my-packages
      sxiv
      ueberzug
      vimv
      xclip
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
  };

  xdg.configFile."calcurse" = {
    source = ../../defaults/calcurse;
    recursive = true;
  };

  xdg.configFile."nvim" = {
    source = ../../defaults/nvim;
    recursive = true;
  };

  nixpkgs.overlays = [
    (self: super: {
      direnv = unstable.direnv;
      fzf = unstable.fzf;
      lf = unstable.lf;
      ookla-speedtest-cli = super.callPackage ./overlays/ookla-speedtest-cli.nix { };
      qutebrowser = unstable.qutebrowser;
      starship = unstable.starship;
      vimv = unstable.vimv;
    })

    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  fonts.fontconfig = {
    enable = true;
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
  };

  programs.qutebrowser = {
    enable = true;
  } // qutebrowserConfig;

  programs.rofi = {
    enable = true;
  } // rofiConfig;

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

  programs.zathura = {
    enable = true;
  } // zathuraConfig;

  services.picom = {
    enable = true;
  } // picomConfig;

  services.polybar = {
    enable = true;
  } // polybarConfig;

  services.sxhkd = {
    enable = true;
  } // sxhkdConfig;

  xsession = {
    enable = true;
    windowManager.bspwm = {
      enable = true;
    } // bspwmConfig;
  };
}
