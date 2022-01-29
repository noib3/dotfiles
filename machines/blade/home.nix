{ config, lib, pkgs, ... }:

let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
  machine = "blade";

  colorscheme = "vscode";
  font-family = "FiraCode Nerd Font";
  palette = import ../../palettes/${colorscheme}.nix;

  hexlib = import ../../palettes/hexlib.nix;

  dirs = {
    configs = ../../configs;
    sync = config.home.homeDirectory + "/Dropbox";
  };

  configs.alacritty = import (dirs.configs + /alacritty) {
    inherit font-family machine palette;
    shell = {
      program = "${unstable.fish}/bin/fish";
      args = [ "--interactive" ];
    };
  };

  configs.bat = import (dirs.configs + /bat);

  configs.bspwm = import (dirs.configs + /bspwm) {
    inherit colorscheme palette;
  };

  dmenu = import (dirs.configs + /dmenu) {
    inherit colorscheme font-family palette;
  };

  configs.dunst = import (dirs.configs + /dunst) {
    inherit colorscheme font-family palette;
  };

  configs.fd = import (dirs.configs + /fd) {
    inherit machine;
  };

  configs.fish = import (dirs.configs + /fish) {
    inherit colorscheme palette;
  };

  configs.fzf = import (dirs.configs + /fzf) {
    inherit colorscheme palette;
  };

  configs.fusuma = import (dirs.configs + /fusuma);

  configs.git = import (dirs.configs + /git) {
    inherit colorscheme;
  };

  configs.gpg = import (dirs.configs + /gpg/gpg.nix) {
    homedir = (dirs.sync + "/share/gnupg");
  };

  configs.gpg-agent = import (dirs.configs + /gpg/gpg-agent.nix);

  configs.lazygit = import (dirs.configs + /lazygit);

  configs.lf = import (dirs.configs + /lf);

  configs.mpv = import (dirs.configs + /mpv);

  configs.picom = import (dirs.configs + /picom);

  configs.polybar = import (dirs.configs + /polybar) {
    inherit colorscheme font-family palette;
  };

  configs.qutebrowser = import (dirs.configs + /qutebrowser) {
    inherit colorscheme font-family palette;
  };

  configs.redshift = import (dirs.configs + /redshift);

  configs.starship = import (dirs.configs + /starship);

  configs.sxhkd = import (dirs.configs + /sxhkd);

  configs.udiskie = import (dirs.configs + /udiskie);

  configs.vivid = import (dirs.configs + /vivid) {
    inherit palette;
  };

  configs.zathura = import (dirs.configs + /zathura) {
    inherit colorscheme font-family palette;
  };

  desktop-items = with pkgs; {
    qutebrowser = makeDesktopItem
      {
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
      };
  };

  language-servers = with pkgs; {
    lua = unstable.sumneko-lua-language-server;
    kotlin = unstable.kotlin-language-server;
    python = unstable.python39Packages.jedi-language-server;
    rust = unstable.rust-analyzer;
    swift = unstable.swift; # sourcekit-lsp is included in swift 
    typescript = unstable.nodePackages.typescript-language-server;
  };

  userscripts = with pkgs; {
    lf = hiPrio (writeShellScriptBin "lf"
      (import (dirs.configs + /lf/launcher.sh.nix)));

    toggle-gaps = writeShellScriptBin "toggle-gaps"
      (builtins.readFile (dirs.configs + /bspwm/scripts/toggle-gaps.sh));

    previewer = writeShellScriptBin "previewer"
      (builtins.readFile (dirs.configs + /lf/previewer.sh));

    rg-previewer = writeShellScriptBin "rg-previewer"
      (builtins.readFile (dirs.configs + /ripgrep/rg-previewer.sh));

    fuzzy-ripgrep = writeShellScriptBin "fuzzy_ripgrep"
      (builtins.readFile (dirs.configs + /fzf/scripts/fuzzy-ripgrep.sh));

    dmenu-open = writeShellScriptBin "dmenu-open"
      (builtins.readFile (dirs.configs + /dmenu/scripts/dmenu-open.sh));

    dmenu-run = writeShellScriptBin "dmenu-run" "dmenu_run -p 'Run>'";

    dmenu-wifi = writers.writePython3Bin "dmenu-wifi"
      { libraries = [ python38Packages.pygobject3 ]; }
      (builtins.readFile (dirs.configs + /dmenu/scripts/dmenu-wifi.py));

    dmenu-bluetooth = writers.writePython3Bin "dmenu-bluetooth" { }
      (builtins.readFile (dirs.configs + /dmenu/scripts/dmenu-bluetooth.py));

    dmenu-powermenu = writers.writePython3Bin "dmenu-powermenu"
      { libraries = [ ]; }
      (builtins.readFile (dirs.configs + /dmenu/scripts/dmenu-powermenu.py));

    dmenu-pulseaudio = writers.writePython3Bin "dmenu-pulseaudio" { }
      (builtins.readFile (dirs.configs + /dmenu/scripts/dmenu-pulseaudio.py));

    dmenu-xembed-qutebrowser = writeShellScriptBin "dmenu-xembed-qute" (
      import (dirs.configs + /dmenu/scripts/dmenu-xembed.sh.nix) {
        inherit colorscheme font-family palette;
      }
    );
  };

  peek = import (dirs.sync + "/projects/peek");
in
{
  imports = [
    ../../modules/programs/fd.nix
    ../../modules/programs/vivid.nix
    ../../modules/services/fusuma.nix
  ];

  home = {
    username = "noib3";
    homeDirectory = "/home/noib3";
    stateVersion = "21.03";

    packages = with pkgs; [
      unstable.androidStudioPackages.canary

      unstable.scrcpy

      peek

      lsof

      unstable.crate2nix
      unstable.ktlint # Kotlin linter/formatter by Pinterest
      unstable.nodePackages.typescript # Used by typescript-language-server
      xtitle
      brave

      unstable.nodejs
      unstable.nodePackages.npm

      calibre # used to get epub image previews inside lf w/ `ebook-meta`

      # nodePackages.node2nix
      # node-packages."@aws-amplify/cli"

      # asciinema
      bitwarden
      bitwarden-cli
      calcurse
      chafa
      delta
      dropbox-cli
      dmenu
      evemu
      evtest
      feh
      ffmpegthumbnailer
      file
      flameshot
      gcc
      gnumake
      glxinfo
      gotop
      graphicsmagick-imagemagick-compat
      libnotify
      lua5_4
      jq
      jmtpfs
      keyutils
      mediainfo
      mkvtoolnix-cli
      neovim-nightly
      networkmanager
      (nerdfonts.override {
        fonts = [
          "FiraCode"
          "Inconsolata"
          "Iosevka"
          "JetBrainsMono"
          "Mononoki"
          "RobotoMono"
        ];
      })
      nixpkgs-fmt
      # nodejs
      pandoc
      pciutils # for lspci
      pfetch
      pick-colour-picker
      pinentry_qt5
      poppler_utils
      unstable.nodePackages.prettier
      proselint # used by ALE for TeX and Markdown formatting
      python39Packages.ipython
      # (python39.withPackages (
      #   ps: with ps; [
      #     ipython
      #     isort
      #     yapf
      #   ]
      # ))
      ripgrep
      rustup
      scrot
      simplescreenrecorder
      speedtest-cli
      unstable.texlive.combined.scheme-full
      tokei
      transmission-remote-gtk
      tree
      tree-sitter
      ueberzug
      unzip
      vimv
      wmctrl
      xclip
      xdotool
      xorg.xev
      xorg.xwininfo
      yarn
      zip
    ]
    ++ (builtins.attrValues desktop-items)
    ++ (builtins.attrValues language-servers)
    ++ (builtins.attrValues userscripts);

    sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim +Man! -";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      COLORTERM = "truecolor";
      LS_COLORS = "$(vivid generate current)";
      LF_ICONS = (builtins.readFile (dirs.configs + /lf/LF_ICONS));
      HISTFILE = "${config.xdg.cacheHome}/bash/bash_history";
      LESSHISTFILE = "${config.xdg.cacheHome}/less/lesshst";
      RIPGREP_CONFIG_PATH = dirs.configs + /ripgrep/ripgreprc;
      OSFONTDIR =
        config.home.homeDirectory
        + "/.nix-profile/share/fonts/truetype/NerdFonts";
      SYNCDIR =
        if lib.pathExists dirs.sync then
          builtins.toString dirs.sync
        else
          "";
      TDTD_DATA_DIR = "${dirs.sync}/tdtd";
      NPM_CONFIG_PREFIX =
        config.home.homeDirectory + "/node_modules";
    };
  };

  nixpkgs.config.allowUnfree = true; # for Dropbox

  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  xdg.configFile = {
    "fusuma/config.yml" = {
      source = (dirs.configs + /fusuma/config.yml);
    };

    "nvim" = {
      source = (dirs.configs + /neovim);
      recursive = true;
    };

    "nvim/lua/colorscheme.lua" = {
      text = import (dirs.configs + /neovim/lua/colorscheme.lua.nix) {
        inherit colorscheme palette;
      };
    };

    "nvim/lua/plug-config/lsp-sumneko-paths.lua" = {
      text = import (dirs.configs + /neovim/lua/plug-config/lsp-sumneko-paths.lua.nix);
    };

    "redshift/hooks/notify-change" = {
      text = import (dirs.configs + /redshift/notify-change.sh.nix);
      executable = true;
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
  } // configs.alacritty;

  programs.bat = {
    enable = true;
  } // configs.bat;

  programs.direnv = {
    enable = true;
  };

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

  programs.mpv = {
    enable = true;
  } // configs.mpv;

  programs.qutebrowser = {
    enable = true;
    package = unstable.qutebrowser;
  } // configs.qutebrowser;

  programs.starship = {
    enable = true;
    package = unstable.starship;
  } // configs.starship;

  programs.vivid = {
    enable = true;
  } // configs.vivid;

  programs.vscode = {
    enable = true;
  };

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
  } // configs.gpg-agent;

  services.mpris-proxy = {
    enable = true;
  };

  services.picom = {
    enable = true;
    package = unstable.picom;
  } // configs.picom;

  services.polybar = {
    enable = true;
    package = pkgs.polybar.override {
      pulseSupport = true;
    };
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

    profileExtra = ''
      ${pkgs.hsetroot}/bin/hsetroot \
        -solid "${hexlib.scale 0.75 palette.primary.background}"
    '';
  };
}
