{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> { };

  font = "roboto-mono";
  colorscheme = "onedark";

  fonts-dir = ./fonts + "/${font}";
  colorschemes-dir = ../../colorschemes + "/${colorscheme}";

  sync-dir = config.home.homeDirectory + "/Sync";
  secrets-dir = sync-dir + "/secrets";
  screenshots-dir = sync-dir + "/screenshots";

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

    take-screenshot = writeScriptBin
      "take-screenshot"
      (import ./scripts/miscellaneous/take-screenshot.nix {
        screenshots-dir = screenshots-dir;
      });

    toggle-gbp = writeScriptBin
      "toggle-gaps-borders-paddings"
      (builtins.readFile ./scripts/miscellaneous/toggle-gaps-borders-paddings);

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
      (import ./overrides/alacritty.nix {
        default = default;
      });

  batConfig = import ../../defaults/bat;

  bspwmConfig = (import ../../defaults/bspwm {
    colors = import (colorschemes-dir + /bspwm.nix);
  });

  direnvConfig = import ../../defaults/direnv;

  dunstConfig = (import ../../defaults/dunst {
    inherit pkgs;
    font = import (fonts-dir + /dunst.nix);
    colors = import (colorschemes-dir + /dunst.nix);
  });

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
      inherit pkgs;
      colors = import (colorschemes-dir + /fish.nix);
    })
    (import ./overrides/fish.nix);

  fzfConfig = (import ../../defaults/fzf {
    colors = import (colorschemes-dir + /fzf.nix);
  });

  gitConfig = import ../../defaults/git;

  gpgAgentConfig = import ../../defaults/gpg/gpg-agent.nix;

  lfConfig = lib.attrsets.recursiveUpdate
    (import ../../defaults/lf {
      inherit pkgs;
    })
    (import ./overrides/lf.nix);

  mpvConfig = import ../../defaults/mpv;

  picomConfig = import ../../defaults/picom;

  polybarConfig = (import ../../defaults/polybar {
    font = import (fonts-dir + /polybar.nix);
    colors = import (colorschemes-dir + /polybar.nix);
  });

  qutebrowserConfig = (import ../../defaults/qutebrowser {
    font = import (fonts-dir + /qutebrowser.nix);
    colors = import (colorschemes-dir + /qutebrowser.nix);
  });

  redshiftConfig = import ../../defaults/redshift;

  rofiConfig = (import ../../defaults/rofi {
    inherit pkgs;
    font = import (fonts-dir + /rofi.nix);
    colors = import (colorschemes-dir + /rofi.nix);
  });

  starshipConfig = import ../../defaults/starship;

  sxhkdConfig = (import ../../defaults/sxhkd {
    secrets-dir = secrets-dir;
  });

  sshConfig = import ../../defaults/ssh;

  tridactylConfig = (import ../../defaults/tridactyl {
    font = import (fonts-dir + /tridactyl.nix);
    colors = import (colorschemes-dir + /tridactyl.nix);
  });

  udiskieConfig = import ../../defaults/udiskie;

  vividConfig = (import ../../defaults/vivid {
    colors = import (colorschemes-dir + /vivid.nix);
  });

  zathuraConfig = (import ../../defaults/zathura {
    font = import (fonts-dir + /zathura.nix);
    colors = import (colorschemes-dir + /zathura.nix);
  });
in
{
  imports = [
    ../../modules/programs/fd.nix
    ../../modules/programs/tridactyl.nix
    ../../modules/programs/vivid.nix
  ];

  nixpkgs.overlays = [
    (self: super: {
      direnv = unstable.direnv;
      fish = unstable.fish;
      fzf = unstable.fzf;
      hideIt = super.callPackage ./overlays/hideIt.nix { };
      lf = unstable.lf;
      ookla-speedtest-cli = super.callPackage ./overlays/ookla-speedtest-cli.nix { };
      picom = unstable.picom;
      python39 = unstable.python39;
      qutebrowser = unstable.qutebrowser;
      starship = unstable.starship;
      tree-sitter = unstable.tree-sitter;
      ueberzug = unstable.ueberzug;
      vimv = unstable.vimv;
    })

    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  home = {
    username = "noib3";
    homeDirectory = "/home/noib3";
    stateVersion = "21.03";

    packages = with pkgs; [
      atool
      bitwarden
      calcurse
      chafa
      evemu
      evtest
      feh
      ffmpegthumbnailer
      file
      fusuma
      gcc
      gotop
      graphicsmagick-imagemagick-compat
      hideIt
      lazygit
      libnotify
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
      nodePackages.vscode-html-languageserver-bin
      nodePackages.vim-language-server
      noto-fonts-emoji
      ookla-speedtest-cli
      pfetch
      pick-colour-picker
      poppler_utils
      (python39.withPackages (
        ps: with ps; [
          ipython
          pynvim
        ]
      ))
      ripgrep
      scrot
      texlab
      texlive.combined.scheme-full
      transmission-remote-gtk
      tree-sitter
      ueberzug
      unclutter-xfixes
      unzip
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

    "fusuma" = {
      source = ../../defaults/fusuma;
      recursive = true;
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

  programs.gpg = {
    enable = true;
  };

  programs.lf = {
    enable = true;
  } // lfConfig;

  programs.mpv = {
    enable = true;
  } // mpvConfig;

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

  services.dunst = {
    enable = true;
  } // dunstConfig;

  services.picom = {
    enable = true;
  } // picomConfig;

  services.gpg-agent = {
    enable = true;
  } // gpgAgentConfig;

  services.polybar = {
    enable = true;
  } // polybarConfig;

  services.redshift = {
    enable = true;
  } // redshiftConfig;

  services.sxhkd = {
    enable = true;
  } // sxhkdConfig;

  services.udiskie = {
    enable = true;
  } // udiskieConfig;

  xsession = {
    enable = true;

    windowManager.bspwm = {
      enable = true;
    } // bspwmConfig;

    pointerCursor = {
      package = pkgs.vanilla-dmz;
      name = "Vanilla-DMZ";
      size = 16;
      defaultCursor = "left_ptr";
    };
  };
}
