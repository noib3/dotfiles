{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> { };

  font = "roboto-mono";
  colorscheme = "onedark";

  fonts-dir = ./fonts + "/${font}";
  colorschemes-dir = ../../colorschemes + "/${colorscheme}";

  sync-dir = config.home.homeDirectory + "/sync";
  secrets-dir = sync-dir + "/secrets";
  screenshots-dir = sync-dir + "/screenshots";

  email-accounts = import ../../defaults/email-accounts;

  userScripts = with pkgs; {
    listen-node-add = writeScriptBin
      "listen-node-add"
      (builtins.readFile ./scripts/bspwm/listen-node-add);

    listen-node-remove = writeScriptBin
      "listen-node-remove"
      (builtins.readFile ./scripts/bspwm/listen-node-remove);

    lf-launcher = writeScriptBin
      "lf"
      (import ../../defaults/lf/launcher.nix { inherit pkgs; });

    fuzzy-opener = writeScriptBin
      "fuzzy-opener"
      (builtins.readFile ./scripts/fuzzy-opener/fuzzy-opener);

    file-open-close = writeScriptBin
      "file-open-close"
      (builtins.readFile ./scripts/miscellaneous/file-open-close);

    neomutt-notify-new = writeScriptBin
      "neomutt-notify-new"
      (builtins.readFile ./scripts/neomutt/notify-new);

    take-screenshot = writeScriptBin
      "take-screenshot"
      (import ./scripts/miscellaneous/take-screenshot.nix {
        screenshots-dir = screenshots-dir;
      });

    toggle-gbp = writeScriptBin
      "toggle-gaps-borders-paddings"
      (builtins.readFile ./scripts/bspwm/toggle-gaps-borders-paddings);

    volumectl = writeScriptBin
      "volumectl"
      (import ./scripts/miscellaneous/volumectl.nix);

    rofi-bluetooth = writeScriptBin
      "rofi-bluetooth"
      (import ./scripts/rofi/rofi-bluetooth.nix {
        colors = import (colorschemes-dir + /polybar.nix);
      });
  };

  desktopItems = with pkgs; {
    qutebrowser = makeDesktopItem {
      name = "qutebrowser";
      desktopName = "qutebrowser";
      exec = "${pkgs.qutebrowser}/bin/qutebrowser";
      mimeType = "x-scheme-handler/unknown;x-scheme-handler/about;x-scheme-handler/https;x-scheme-handler/http;text/html";
      icon = "qutebrowser";
    };
  };

  configs = {
    alacritty =
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

    bat = import ../../defaults/bat;

    bspwm = (import ../../defaults/bspwm {
      colors = import (colorschemes-dir + /bspwm.nix);
    });

    direnv = import ../../defaults/direnv;

    dunst = (import ../../defaults/dunst {
      inherit pkgs;
      font = import (fonts-dir + /dunst.nix);
      colors = import (colorschemes-dir + /dunst.nix);
    });

    fd =
      let
        default = import ../../defaults/fd;
      in
      import ./overrides/fd.nix { default = default; };

    firefox = (import ../../defaults/firefox {
      font = import (fonts-dir + /firefox.nix);
      colors = import (colorschemes-dir + /firefox.nix);
    });

    fish = lib.attrsets.recursiveUpdate
      (import ../../defaults/fish {
        inherit pkgs;
        colors = import (colorschemes-dir + /fish.nix);
      })
      (import ./overrides/fish.nix);

    fzf = (import ../../defaults/fzf {
      colors = import (colorschemes-dir + /fzf.nix);
    });

    fusuma = import ../../defaults/fusuma;

    git = import ../../defaults/git;

    gpgAgent = import ../../defaults/gpg/gpg-agent.nix;

    lf = lib.attrsets.recursiveUpdate
      (import ../../defaults/lf {
        inherit pkgs;
      })
      (import ./overrides/lf.nix);

    mpv = import ../../defaults/mpv;

    neomutt = import ../../defaults/neomutt;

    password-store = import ../../defaults/password-store;

    picom = import ../../defaults/picom;

    polybar = (import ../../defaults/polybar {
      font = import (fonts-dir + /polybar.nix);
      colors = import (colorschemes-dir + /polybar.nix);
    });

    qutebrowser = (import ../../defaults/qutebrowser {
      font = import (fonts-dir + /qutebrowser.nix);
      colors = import (colorschemes-dir + /qutebrowser.nix);
    });

    redshift = import ../../defaults/redshift;

    rofi = (import ../../defaults/rofi {
      inherit pkgs;
      font = import (fonts-dir + /rofi.nix);
      colors = import (colorschemes-dir + /rofi.nix);
    });

    starship = import ../../defaults/starship;

    sxhkd = (import ../../defaults/sxhkd {
      secrets-dir = secrets-dir;
    });

    ssh = import ../../defaults/ssh;

    tridactyl = (import ../../defaults/tridactyl {
      font = import (fonts-dir + /tridactyl.nix);
      colors = import (colorschemes-dir + /tridactyl.nix);
    });

    udiskie = import ../../defaults/udiskie;

    vivid = (import ../../defaults/vivid {
      colors = import (colorschemes-dir + /vivid.nix);
    });

    zathura = (import ../../defaults/zathura {
      font = import (fonts-dir + /zathura.nix);
      colors = import (colorschemes-dir + /zathura.nix);
    });
  };
in
{
  imports = [
    ../../modules/programs/fd.nix
    ../../modules/programs/tridactyl.nix
    ../../modules/programs/vivid.nix
    ../../modules/services/fusuma.nix
    ../../modules/services/mpris.nix
  ];

  accounts.email = email-accounts;

  home = {
    username = "noib3";
    homeDirectory = "/home/noib3";
    stateVersion = "21.03";

    packages = with pkgs; [
      atool
      bitwarden
      bitwarden-cli
      buku
      calcurse
      calibre
      evemu
      evtest
      feh
      ffmpegthumbnailer
      file
      fusuma
      gcc
      git-crypt
      gotop
      graphicsmagick-imagemagick-compat
      hideIt
      # hydroxide
      lazygit
      libnotify
      mediainfo
      mkvtoolnix-cli
      neovim-nightly
      (nerdfonts.override {
        fonts = [
          "JetBrainsMono"
          "RobotoMono"
        ];
      })
      nixpkgs-fmt
      nodejs
      nodePackages.vscode-html-languageserver-bin
      nodePackages.vim-language-server
      noto-fonts-emoji
      ookla-speedtest-cli
      pandoc
      pfetch
      pick-colour-picker
      poppler_utils
      protonmail-bridge
      (python39.withPackages (
        ps: with ps; [
          autopep8
          ipython
          isort
          pynvim
        ]
      ))
      ripgrep
      scrot
      sxiv
      unstable.texlive.combined.scheme-full
      transmission-remote-gtk
      tree
      tree-sitter
      ueberzug
      unclutter-xfixes
      unzip
      vimiv-qt
      vimv
      wmctrl
      xbanish
      xclip
      xdotool
      xorg.xev
      xorg.xwininfo
      yarn
    ] ++ [
      userScripts.listen-node-add
      userScripts.listen-node-remove
      (pkgs.hiPrio userScripts.lf-launcher)
      userScripts.fuzzy-opener
      userScripts.file-open-close
      userScripts.neomutt-notify-new
      userScripts.take-screenshot
      userScripts.toggle-gbp
      userScripts.volumectl
      userScripts.rofi-bluetooth
    ] ++ [
      desktopItems.qutebrowser
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
    };
  };

  nixpkgs.overlays = [
    (self: super: {
      direnv = unstable.direnv;
      fish = unstable.fish;
      fzf = unstable.fzf;
      hideIt = super.callPackage ./overlays/hideIt.nix { };
      # hydroxide = unstable.hydroxide;
      lf = unstable.lf;
      ookla-speedtest-cli = super.callPackage ./overlays/ookla-speedtest-cli.nix { };
      picom = unstable.picom;
      python39 = unstable.python39;
      qutebrowser = unstable.qutebrowser;
      starship = unstable.starship;
      tree-sitter = unstable.tree-sitter;
      ueberzug = unstable.ueberzug;
      vimiv-qt = unstable.vimiv-qt;
      vimv = unstable.vimv;
    })

    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  xdg.configFile = {
    "alacritty/fuzzy-opener.yml" = {
      text = lib.replaceStrings [ "\\\\" ] [ "\\" ]
        (builtins.toJSON (import ./scripts/fuzzy-opener/alacritty.nix {
          font = import (fonts-dir + /alacritty.nix);
          colors = import (colorschemes-dir + /alacritty.nix);
        }));
      # source =
      #   let
      #     yaml = pkgs.formats.yaml { };
      #   in
      #   yaml.generate "fuzzy-opener.yml"
      #     (import ./scripts/fuzzy-opener/alacritty.nix {
      #       font = import (fonts-dir + /alacritty.nix);
      #       colors = import (colorschemes-dir + /alacritty.nix);
      #     });
    };

    "calcurse" = {
      source = ../../defaults/calcurse;
      recursive = true;
    };

    "calcurse/hooks/post-save" = {
      source = ./scripts/calcurse/post-save;
    };

    "fusuma/config.yml" = {
      source = ../../defaults/fusuma/config.yml;
    };

    "lazygit/config.yml" = {
      source = ../../defaults/lazygit/config.yml;
    };

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

    "qutebrowser/userscripts" = {
      source = ./scripts/qutebrowser;
      recursive = true;
    };

    "redshift/hooks/notify-change" = {
      source = ./scripts/redshift/notify-change;
    };

    "wallpaper.png" = {
      source = colorschemes-dir + /wallpaper.png;
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "qutebrowser.desktop" ];
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
    };
  };

  fonts.fontconfig = {
    enable = true;
  };

  programs = {
    home-manager = {
      enable = true;
    };

    alacritty = {
      enable = true;
    } // configs.alacritty;

    bat = {
      enable = true;
    } // configs.bat;

    direnv = {
      enable = true;
    } // configs.direnv;

    fd = {
      enable = true;
    } // configs.fd;

    firefox = {
      enable = true;
    } // configs.firefox;

    fish = {
      enable = true;
    } // configs.fish;

    fzf = {
      enable = true;
    } // configs.fzf;

    git = {
      enable = true;
    } // configs.git;

    gpg = {
      enable = true;
    };

    lf = {
      enable = true;
    } // configs.lf;

    mpv = {
      enable = true;
    } // configs.mpv;

    neomutt = {
      enable = true;
    } // configs.neomutt;

    password-store = {
      enable = true;
    } // configs.password-store;

    qutebrowser = {
      enable = true;
    } // configs.qutebrowser;

    rofi = {
      enable = true;
    } // configs.rofi;

    ssh = {
      enable = true;
    } // configs.ssh;

    starship = {
      enable = true;
    } // configs.starship;

    tridactyl = {
      enable = true;
    } // configs.tridactyl;

    vivid = {
      enable = true;
    } // configs.vivid;

    zathura = {
      enable = true;
    } // configs.zathura;
  };

  services = {
    dunst = {
      enable = true;
    } // configs.dunst;

    # fusuma = {
    #   enable = true;
    # } // configs.fusuma;

    gpg-agent = {
      enable = true;
    } // configs.gpgAgent;

    mpris = {
      enable = true;
    };

    picom = {
      enable = true;
    } // configs.picom;

    polybar = {
      enable = true;
    } // configs.polybar;

    redshift = {
      enable = true;
    } // configs.redshift;

    sxhkd = {
      enable = true;
    } // configs.sxhkd;

    udiskie = {
      enable = true;
    } // configs.udiskie;
  };

  xsession = {
    enable = true;

    windowManager.bspwm = {
      enable = true;
    } // configs.bspwm;

    pointerCursor = {
      package = pkgs.vanilla-dmz;
      name = "Vanilla-DMZ";
      size = 16;
      defaultCursor = "left_ptr";
    };
  };
}
