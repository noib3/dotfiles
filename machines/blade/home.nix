{ config, lib, pkgs, ... }:

let
  unstable = import <nixos-unstable> { };
  machine = "blade";

  colorscheme = "onedark";
  font = "fira-code";

  dirs = {
    colorscheme = ../../colorschemes + "/${colorscheme}";
    configs = ../../configs;
    font = ../../fonts + "/${font}";
    sync = config.home.homeDirectory + "/Dropbox";
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

  configs.bspwm = import (dirs.configs + /bspwm) {
    colors = import (dirs.colorscheme + /bspwm.nix);
  };

  dmenu = import (dirs.configs + /dmenu) {
    font = import (dirs.font + /dmenu.nix);
    colors = import (dirs.colorscheme + /dmenu.nix);
  };

  configs.dunst = import (dirs.configs + /dunst) {
    font = import (dirs.font + /dunst.nix);
    colors = import (dirs.colorscheme + /dunst.nix);
  };

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

  configs.fusuma = import (dirs.configs + /fusuma);

  configs.git = import (dirs.configs + /git);

  configs.gpg = import (dirs.configs + /gpg/gpg.nix) {
    homedir = (dirs.sync + "/share/gnupg");
  };

  configs.gpg-agent = import (dirs.configs + /gpg/gpg-agent.nix);

  configs.lazygit = import (dirs.configs + /lazygit);

  configs.lf = import (dirs.configs + /lf);

  configs.mpv = import (dirs.configs + /mpv);

  configs.picom = import (dirs.configs + /picom);

  configs.polybar = import (dirs.configs + /polybar) {
    fonts = import (dirs.font + /polybar.nix);
    colors = import (dirs.colorscheme + /polybar.nix);
  };

  configs.qutebrowser = import (dirs.configs + /qutebrowser) {
    font = import (dirs.font + /qutebrowser.nix);
    colors = import (dirs.colorscheme + /qutebrowser.nix);
  };

  configs.redshift = import (dirs.configs + /redshift);

  configs.starship = import (dirs.configs + /starship);

  configs.sxhkd = import (dirs.configs + /sxhkd);

  configs.tridactyl = import (dirs.configs + /tridactyl) {
    font = import (dirs.font + /tridactyl.nix);
    colors = import (dirs.colorscheme + /tridactyl.nix);
  };

  configs.udiskie = import (dirs.configs + /udiskie);

  configs.vivid = import (dirs.configs + /vivid) {
    colors = import (dirs.colorscheme + /vivid.nix);
  };

  configs.zathura = import (dirs.configs + /zathura) {
    font = import (dirs.font + /zathura.nix);
    colors = import (dirs.colorscheme + /zathura.nix);
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
    lua = sumneko-lua-language-server;
    bash = nodePackages.bash-language-server;
    python = nodePackages.pyright;
    vimscript = nodePackages.vim-language-server;
  };

  userscripts = with pkgs; {
    lf = hiPrio (writeShellScriptBin "lf"
      (import (dirs.configs + /lf/launcher.sh.nix)));

    weather = writers.writePython3Bin "weather"
      { libraries = [ python38Packages.requests ]; }
      (builtins.readFile (dirs.configs + /eww/weather/weather.py));

    previewer = writeShellScriptBin "previewer"
      (builtins.readFile (dirs.configs + /lf/previewer.sh));

    rg-previewer = writeShellScriptBin "rg-previewer"
      (builtins.readFile (dirs.configs + /fzf/scripts/rg-previewer.sh));

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

    dmenu-powermenu = writers.writePython3Bin "dmenu-powermenu" { }
      (builtins.readFile (dirs.configs + /dmenu/scripts/dmenu-powermenu.py));

    dmenu-pulseaudio = writers.writePython3Bin "dmenu-pulseaudio" { }
      (builtins.readFile (dirs.configs + /dmenu/scripts/dmenu-pulseaudio.py));

    dmenu-xembed-qutebrowser = writeShellScriptBin "dmenu-xembed-qute" (
      import (dirs.configs + /dmenu/scripts/dmenu-xembed.sh.nix) {
        font = (import (dirs.font + /qutebrowser.nix)).dmenu;
        colors = (import (dirs.colorscheme + /qutebrowser.nix)).dmenu;
      }
    );
  };
in
{
  imports = [
    ../../modules/programs/fd.nix
    ../../modules/programs/tridactyl.nix
    ../../modules/programs/vivid.nix
    ../../modules/services/fusuma.nix
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
      chafa
      delta
      dropbox-cli
      dmenu
      evemu
      evtest
      feh
      ffmpegthumbnailer
      file
      gcc
      gnumake
      glxinfo
      gotop
      graphicsmagick-imagemagick-compat
      inkscape
      libnotify
      jmtpfs
      keyutils
      mediainfo
      mkvtoolnix-cli
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
      pandoc
      pciutils # for lspci
      pfetch
      pick-colour-picker
      pinentry_qt5
      poppler_utils
      proselint # used by ALE for TeX and Markdown formatting
      (python39.withPackages (
        ps: with ps; [
          autopep8
          ipython
          isort
          pynvim
        ]
      ))
      ripgrep
      rustup
      scrot
      speedtest-cli
      unstable.texlive.combined.scheme-full
      transmission-remote-gtk
      tree
      ueberzug
      unzip
      vimv
      wmctrl
      xclip
      xdotool
      xorg.xev
      xorg.xwininfo
      yarn
    ]
    ++ (builtins.attrValues desktop-items)
    ++ (builtins.attrValues language-servers)
    ++ (builtins.attrValues userscripts);

    sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim -c 'set ft=man' -";
      LANG = " en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      COLORTERM = "truecolor";
      LS_COLORS = "$(vivid generate current)";
      LF_ICONS = (builtins.readFile (dirs.configs + /lf/LF_ICONS));
      HISTFILE = "${config.xdg.cacheHome}/bash/bash_history";
      LESSHISTFILE = "${config.xdg.cacheHome}/less/lesshst";
      RIPGREP_CONFIG_PATH = dirs.configs + /ripgrep/ripgreprc;
      SYNCDIR =
        if lib.pathExists dirs.sync then
          builtins.toString dirs.sync
        else
          "";
    };
  };

  nixpkgs.config.allowUnfree = true; # for Dropbox

  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  xdg.configFile = {
    "eww" = {
      source = (dirs.configs + /eww);
      recursive = true;
    };

    "fusuma/config.yml" = {
      source = (dirs.configs + /fusuma/config.yml);
    };

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
      ${pkgs.feh}/bin/feh --bg-fill --no-fehbg \
      ${builtins.toString (dirs.colorscheme + /background.png)}
    '';
  };
}
