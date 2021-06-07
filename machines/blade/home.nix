{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> { };

  colorscheme = "onedark";
  font = "roboto-mono";

  dirs = {
    colorscheme = ../../colorschemes + "/${colorscheme}";
    defaults = ../../defaults;
    font = ./fonts + "/${font}";
    projects = config.home.homeDirectory + "/sync/projects";
    screenshots = config.home.homeDirectory + "/sync/screenshots";
  };

  devTools = with pkgs; [
    gcc
    gnumake
  ];

  languageServers = with pkgs; [
    unstable.sumneko-lua-language-server
    nodePackages.vim-language-server
    nodePackages.vscode-html-languageserver-bin
  ];

  desktopItems = with pkgs; [
    (makeDesktopItem {
      name = "qutebrowser";
      desktopName = "qutebrowser";
      exec = "${pkgs.qutebrowser}/bin/qutebrowser";
      mimeType = lib.concatStringsSep ";" [
        "text/html"
        "x-scheme-handler/about"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/unknown"
      ];
      icon = "qutebrowser";
    })
  ];

  userScripts = with pkgs; [
    (writeShellScriptBin "peek"
      (builtins.readFile (dirs.projects + "/peek/peek")))

    (writeShellScriptBin "dmenu-bluetooth"
      (builtins.readFile (dirs.defaults + /dmenu/scripts/dmenu-bluetooth)))

    (writeShellScriptBin "dmenu-open"
      (builtins.readFile (dirs.defaults + /dmenu/scripts/dmenu-open)))

    (writeShellScriptBin "dmenu-wifi"
      (builtins.readFile (dirs.defaults + /dmenu/scripts/dmenu-wifi)))

    (writeShellScriptBin "dmenu-xembed-qute"
      (import (dirs.defaults + /dmenu/scripts/dmenu-xembed-qute.nix) {
        font = (import (dirs.font + /qutebrowser.nix)).dmenu;
        colors = (import (dirs.colorscheme + /dmenu.nix)).qutebrowser;
      }))

    (hiPrio (writeShellScriptBin "lf"
      (import (dirs.defaults + /lf/launcher.nix) { inherit pkgs; })))

    (writeScriptBin "file-open-close"
      (builtins.readFile ./scripts/miscellaneous/file-open-close))

    (writeScriptBin "take-screenshot"
      (import ./scripts/miscellaneous/take-screenshot.nix {
        screenshots-dir = dirs.screenshots;
      }))

    (writeScriptBin "toggle-gaps-borders-paddings"
      (builtins.readFile (dirs.defaults + /bspwm/scripts/toggle-gaps-borders-paddings)))

    (writeScriptBin "volumectl"
      (import ./scripts/miscellaneous/volumectl.nix))

    (writeScriptBin "rofi-bluetooth"
      (import ./scripts/rofi/rofi-bluetooth.nix {
        colors = import (dirs.colorscheme + /polybar.nix);
      }))
  ];

  configs.alacritty =
    let
      default = (import (dirs.defaults + /alacritty) {
        pkgs = unstable;
        font = import (dirs.font + /alacritty.nix);
        colors = import (dirs.colorscheme + /alacritty.nix);
      });
    in
    lib.attrsets.recursiveUpdate
      default
      (import ./overrides/alacritty.nix { default = default; });

  configs.bat = import (dirs.defaults + /bat);

  configs.bspwm = (import (dirs.defaults + /bspwm) {
    colors = import (dirs.colorscheme + /bspwm.nix);
  });

  configs.direnv = import (dirs.defaults + /direnv);

  configs.dunst = (import (dirs.defaults + /dunst) {
    inherit pkgs;
    font = import (dirs.font + /dunst.nix);
    colors = import (dirs.colorscheme + /dunst.nix);
  });

  configs.fd =
    let
      default = import (dirs.defaults + /fd);
    in
    import ./overrides/fd.nix { default = default; };

  configs.firefox = (import (dirs.defaults + /firefox) {
    font = import (dirs.font + /firefox.nix);
    colors = import (dirs.colorscheme + /firefox.nix);
  });

  configs.fish = lib.attrsets.recursiveUpdate
    (import (dirs.defaults + /fish) {
      inherit pkgs;
      colors = import (dirs.colorscheme + /fish.nix);
    })
    (import ./overrides/fish.nix);

  configs.fzf = (import (dirs.defaults + /fzf) {
    colors = import (dirs.colorscheme + /fzf.nix);
  });

  configs.fusuma = import (dirs.defaults + /fusuma);

  configs.git = import (dirs.defaults + /git);

  configs.gpgAgent = import (dirs.defaults + /gpg/gpg-agent.nix);

  configs.lf = lib.attrsets.recursiveUpdate
    (import (dirs.defaults + /lf) { inherit pkgs; })
    (import ./overrides/lf.nix);

  configs.mpv = import (dirs.defaults + /mpv);

  configs.picom = import (dirs.defaults + /picom);

  configs.polybar = (import (dirs.defaults + /polybar) {
    font = import (dirs.font + /polybar.nix);
    colors = import (dirs.colorscheme + /polybar.nix);
  });

  configs.qutebrowser = (import (dirs.defaults + /qutebrowser) {
    font = import (dirs.font + /qutebrowser.nix);
    colors = import (dirs.colorscheme + /qutebrowser.nix);
  });

  configs.redshift = import (dirs.defaults + /redshift);

  configs.starship = (import (dirs.defaults + /starship) {
    inherit lib;
  });

  configs.sxhkd = import (dirs.defaults + /sxhkd);

  configs.ssh = import (dirs.defaults + /ssh);

  configs.tridactyl = (import (dirs.defaults + /tridactyl) {
    font = import (dirs.font + /tridactyl.nix);
    colors = import (dirs.colorscheme + /tridactyl.nix);
  });

  configs.udiskie = import (dirs.defaults + /udiskie);

  configs.vivid = (import (dirs.defaults + /vivid) {
    colors = import (dirs.colorscheme + /vivid.nix);
  });

  configs.zathura = (import (dirs.defaults + /zathura) {
    font = import (dirs.font + /zathura.nix);
    colors = import (dirs.colorscheme + /zathura.nix);
  });
in
{
  imports = [
    ../../modules/programs/fd.nix
    ../../modules/programs/tridactyl.nix
    ../../modules/programs/vivid.nix
    ../../modules/services/fusuma.nix
    ../../modules/services/mpris.nix
  ];

  home = {
    username = "noib3";
    homeDirectory = "/home/noib3";
    stateVersion = "21.03";

    packages = with pkgs; [
      atool
      bitwarden
      bitwarden-cli
      calcurse
      calibre
      dmenu
      dragon-drop
      evemu
      evtest
      feh
      ffmpegthumbnailer
      file
      fusuma
      git-crypt
      gotop
      graphicsmagick-imagemagick-compat
      hideIt
      lazygit
      libnotify
      lua5_4
      jmtpfs
      jq # A cli JSON parser
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
      noto-fonts-emoji
      ookla-speedtest-cli
      pandoc
      pfetch
      pick-colour-picker
      pinentry_qt5 # GnuPG's cli interface to passphrase input
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
    ]
    ++ devTools
    ++ languageServers
    ++ userScripts
    ++ desktopItems;

    sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim -c 'set ft=man' -";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      COLORTERM = "truecolor";
      LS_COLORS = "$(vivid generate current)";
      HISTFILE = "${config.xdg.cacheHome}/bash/bash_history";
      LESSHISTFILE = "${config.xdg.cacheHome}/less/lesshst";
      RIPGREP_CONFIG_PATH = dirs.defaults + /ripgrep/ripgreprc;
    };
  };

  nixpkgs.overlays = [
    (self: super: {
      dmenu = super.callPackage (dirs.defaults + /dmenu) {
        font = import (dirs.font + /dmenu.nix);
        colors = import (dirs.colorscheme + /dmenu.nix);
      };
      direnv = unstable.direnv;
      fzf = unstable.fzf;
      hideIt = super.callPackage ./overlays/hideIt.nix { };
      lf = unstable.lf;
      lua5_4 = unstable.lua5_4;
      ookla-speedtest-cli = super.callPackage ./overlays/ookla-speedtest-cli.nix { };
      python39 = unstable.python39;
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
          font = import (dirs.font + /alacritty.nix);
          colors = import (dirs.colorscheme + /alacritty.nix);
        }));
      # source =
      #   let
      #     yaml = pkgs.formats.yaml { };
      #   in
      #   yaml.generate "fuzzy-opener.yml"
      #     (import ./scripts/fuzzy-opener/alacritty.nix {
      #       font = import (dirs.font + /alacritty.nix);
      #       colors = import (colorschemes + /alacritty.nix);
      #     });
    };

    "fusuma/config.yml" = {
      source = (dirs.defaults + /fusuma/config.yml);
    };

    "lazygit/config.yml" = {
      source = (dirs.defaults + /lazygit/config.yml);
    };

    "nvim" = {
      source = (dirs.defaults + /neovim);
      recursive = true;
    };

    "nvim/lua/colorscheme/init.lua" = {
      text = (import (dirs.defaults + /neovim/lua/colorscheme/init.lua.nix) {
        inherit lib;
        colors = import (dirs.colorscheme + /neovim.nix);
      });
    };

    "nvim/lua/options/spellfile.lua" = {
      text = import (dirs.defaults + /neovim/lua/options/spellfile.lua.nix);
    };

    "qutebrowser/userscripts" = {
      source = (dirs.defaults + /qutebrowser/userscripts);
      recursive = true;
    };

    "redshift/hooks/notify-change" = {
      source = ./scripts/redshift/notify-change;
    };

    "wallpaper.png" = {
      source = dirs.colorscheme + /wallpaper.png;
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

  programs.home-manager = {
    enable = true;
  };

  programs.alacritty = {
    enable = true;
    package = unstable.alacritty;
  } // configs.alacritty;

  programs.bat = {
    enable = true;
  } // configs.bat;

  programs.direnv = {
    enable = true;
  } // configs.direnv;

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
  } // configs.fzf;

  programs.git = {
    enable = true;
  } // configs.git;

  programs.gpg = {
    enable = true;
  };

  programs.lf = {
    enable = true;
  } // configs.lf;

  programs.mpv = {
    enable = true;
  } // configs.mpv;

  programs.qutebrowser = {
    enable = true;
    package = unstable.qutebrowser;
  } // configs.qutebrowser;

  programs.rofi = {
    enable = true;
  };

  programs.ssh = {
    enable = true;
  } // configs.ssh;

  programs.starship = {
    enable = true;
    package = unstable.starship;
  } // configs.starship;

  programs.tridactyl = {
    enable = true;
  } // configs.tridactyl;

  programs.vivid = {
    enable = true;
  } // configs.vivid;

  programs.zathura = {
    enable = true;
  } // configs.zathura;

  services.dunst = {
    enable = true;
  } // configs.dunst;

  # services.fusuma = {
  #   enable = true;
  # } // configs.fusuma;

  services.gpg-agent = {
    enable = true;
  } // configs.gpgAgent;

  services.mpris = {
    enable = true;
  };

  services.picom = {
    enable = true;
    package = unstable.picom;
  } // configs.picom;

  services.polybar = {
    enable = true;
  } // configs.polybar;

  services.redshift = {
    enable = true;
  } // configs.redshift;

  services.sxhkd = {
    enable = true;
  } // configs.sxhkd;

  services.udiskie = {
    enable = true;
  } // configs.udiskie;

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
