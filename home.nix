{ machine
, colorscheme
, palette
, font-family
, configDir
, cloudDir
, overlays
, modules
, hexlib
}:

{ pkgs, lib, config, ... }:

let
  fuzzy-ripgrep = pkgs.writeShellScriptBin "fuzzy_ripgrep"
    (builtins.readFile "${configDir}/fzf/scripts/fuzzy-ripgrep.sh");

  lf_w_image_previews = with pkgs; hiPrio (writeShellScriptBin "lf"
    (import "${configDir}/lf/launcher.sh.nix" { inherit lf; })
  );

  previewer = pkgs.writeShellScriptBin "previewer"
    (builtins.readFile "${configDir}/lf/previewer.sh");

  rg-previewer = pkgs.writeShellScriptBin "rg-previewer"
    (builtins.readFile "${configDir}/ripgrep/rg-previewer.sh");
in
{
  imports = modules;

  nixpkgs = {
    config.allowUnfree = true;
    overlays = overlays;
  };

  home.packages = with pkgs; [
    brave
    calibre # Used by lf to get image previews for .epub files via `ebook-meta`
    chafa
    delta
    fd
    ffmpegthumbnailer
    file
    fuzzy-ripgrep
    gcc # Used by tree-sitter to compile grammars
    gotop
    jq
    kotlin-language-server
    ktlint
    imagemagick_light # Contains `convert`
    mediainfo
    mkvtoolnix-cli # Used by lf to get image previews for videos
    neovim-nightly
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
    pfetch
    previewer
    (python310.withPackages (pp: with pp; [
      ipython
      isort
      jedi-language-server
      yapf
    ]))
    rg-previewer
    ripgrep
    rnix-lsp
    rust-analyzer
    rustup
    sumneko-lua-language-server
    tdtd
    texlive.combined.scheme-full
    tokei
    unzip
    vimv
    zip
  ] ++ lib.lists.optionals pkgs.stdenv.isDarwin [
    findutils
    gnused
  ] ++ lib.lists.optionals pkgs.stdenv.isLinux [
    calcurse
    dmenu
    feh
    flameshot
    lf_w_image_previews
    libnotify
    pick-colour-picker
    ueberzug
    wmctrl
    xclip
    xdotool
    xorg.xev
    xorg.xwininfo
    xtitle
    (pkgs.makeDesktopItem {
      name = "qutebrowser";
      desktopName = "qutebrowser";
      exec = "${pkgs.qutebrowser}/bin/qutebrowser";
      mimeType = lib.concatStringsSep ";" [
        "text/html"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
      icon = "qutebrowser";
    })
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    MANPAGER = "nvim +Man! -";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    COLORTERM = "truecolor";
    LS_COLORS = "$(vivid generate current)";
    LF_ICONS = (builtins.readFile "${configDir}/lf/LF_ICONS");
    HISTFILE = "${config.xdg.cacheHome}/bash/bash_history";
    LESSHISTFILE = "${config.xdg.cacheHome}/less/lesshst";
    RIPGREP_CONFIG_PATH = "${configDir}/ripgrep/ripgreprc";
    TDTD_DATA_DIR = "${cloudDir}/tdtd";
    OSFONTDIR = lib.strings.optionalString pkgs.stdenv.isLinux (
      config.home.homeDirectory
      + "/.nix-profile/share/fonts/truetype/NerdFonts"
    );
  };

  xdg.configFile = {
    "fd/ignore" = {
      source = "${configDir}/fd/ignore";
    };

    "fusuma/config.yml" = lib.mkIf pkgs.stdenv.isLinux {
      source = "${configDir}/fusuma/config.yml";
    };

    "nvim" = {
      source = "${configDir}/neovim";
      recursive = true;
    };

    "nvim/lua/colorscheme.lua" = {
      text = import "${configDir}/neovim/lua/colorscheme.lua.nix" {
        inherit colorscheme palette;
      };
    };

    "nvim/lua/plug-config/lsp-sumneko-paths.lua" = {
      text = import
        "${configDir}/neovim/lua/plug-config/lsp-sumneko-paths.lua.nix"
        {
          inherit (pkgs) sumneko-lua-language-server;
        };
    };

    "redshift/hooks/notify-change" = {
      text = import "${configDir}/redshift/notify-change.sh.nix" {
        inherit pkgs;
      };
      executable = true;
    };
  };

  xdg.mimeApps = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "text/html" = [ "qutebrowser.desktop" ];
      "x-scheme-handler/http" = [ "qutebrowser.desktop" ];
      "x-scheme-handler/https" = [ "qutebrowser.desktop" ];
    };
  };

  fonts.fontconfig = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
  };

  programs.alacritty = {
    enable = true;
  } // (import "${configDir}/alacritty" {
    inherit font-family machine palette;
    inherit (lib.lists) optionals;
    inherit (pkgs.stdenv) isDarwin isLinux;
    shell = {
      program = "${pkgs.fish}/bin/fish";
      args = [ "--interactive" ];
    };
  });

  programs.bat = {
    enable = true;
  } // (import "${configDir}/bat");

  programs.direnv = {
    enable = true;
  };

  programs.fish = {
    enable = true;
  } // (import "${configDir}/fish" {
    inherit pkgs colorscheme palette cloudDir;
    inherit (lib.strings) removePrefix;
  });

  programs.fzf = {
    enable = true;
  } // (import "${configDir}/fzf" {
    inherit colorscheme palette hexlib;
    inherit (lib) concatStringsSep;
    inherit (lib.strings) removePrefix;
  });

  programs.git = {
    enable = true;
  } // (import "${configDir}/git" { inherit colorscheme; });

  programs.gpg = {
    enable = true;
  } // (import "${configDir}/gpg/gpg.nix" {
    homedir = "${cloudDir}/share/gnupg";
  });

  programs.home-manager = {
    enable = true;
  };

  programs.lazygit = {
    enable = true;
  } // (import "${configDir}/lazygit");

  programs.lf = {
    enable = true;
  } // (import "${configDir}/lf" { inherit pkgs; });

  programs.mpv = {
    enable = true;
  } // (import "${configDir}/mpv");

  programs.qutebrowser = {
    enable = true;
  } // (import "${configDir}/qutebrowser" {
    inherit pkgs colorscheme font-family palette hexlib;
  });

  programs.skhd = lib.mkIf pkgs.stdenv.isDarwin
    {
      enable = true;
    } // (import "${configDir}/skhd");

  programs.spacebar = lib.mkIf pkgs.stdenv.isDarwin ({
    enable = true;
  } // (import "${configDir}/spacebar" {
    inherit colorscheme font-family palette;
    inherit (lib.strings) removePrefix;
  }));

  programs.starship = {
    enable = true;
  } // (import "${configDir}/starship" { inherit (lib) concatStrings; });

  programs.vivid = {
    enable = true;
  } // (import "${configDir}/vivid" {
    inherit palette;
    inherit (lib.strings) removePrefix;
  });

  programs.yabai = lib.mkIf pkgs.stdenv.isDarwin ({
    enable = true;
  } // (import "${configDir}/yabai" {
    inherit colorscheme palette hexlib;
    inherit (lib.strings) removePrefix;
  }));

  programs.zathura = lib.mkIf pkgs.stdenv.isLinux ({
    enable = true;
  } // (import "${configDir}/zathura" {
    inherit colorscheme font-family palette hexlib;
  }));

  services.dunst = lib.mkIf pkgs.stdenv.isLinux ({
    enable = true;
  } // (import "${configDir}/dunst" {
    inherit colorscheme font-family palette hexlib;
    inherit (pkgs) hicolor-icon-theme;
  }));

  # services.fusuma = {
  #   enable = true;
  # } // (import "${configDir}/fusuma");

  services.gpg-agent = lib.mkIf pkgs.stdenv.isLinux ({
    enable = true;
  } // (import "${configDir}/gpg/gpg-agent.nix"));

  services.mpris-proxy = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
  };

  services.picom = lib.mkIf pkgs.stdenv.isLinux ({
    enable = true;
  } // (import "${configDir}/picom"));

  services.polybar = lib.mkIf pkgs.stdenv.isLinux ({
    enable = true;
    package = pkgs.polybar.override {
      pulseSupport = true;
    };
  } // (import "${configDir}/polybar" {
    inherit colorscheme font-family palette hexlib;
    inherit (lib) concatStringsSep;
  }));

  services.redshift = lib.mkIf pkgs.stdenv.isLinux ({
    enable = true;
  } // (import "${configDir}/redshift"));

  services.sxhkd = lib.mkIf pkgs.stdenv.isLinux ({
    enable = true;
  } // (import "${configDir}/sxhkd" {
    inherit configDir cloudDir;
    inherit (pkgs) writeShellScriptBin;
    inherit (pkgs.writers) writePython3Bin;
  }));

  services.udiskie = lib.mkIf pkgs.stdenv.isLinux ({
    enable = true;
  } // (import "${configDir}/udiskie"));

  xsession = lib.mkIf pkgs.stdenv.isLinux ({
    enable = true;

    windowManager.bspwm = {
      enable = true;
    } // (import "${configDir}/bspwm") {
      inherit pkgs colorscheme palette hexlib;
    };

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
  });
}
