{
  pkgs,
  lib,
  config,
  colorscheme,
  font,
  machine,
  ...
}:

let
  inherit (pkgs.stdenv) isDarwin isLinux;

  configDir = ./home;

  font-family = font;

  hexlib = import ./lib/hex.nix { inherit (pkgs) lib; };

  palette = import (./palettes + "/${colorscheme}.nix");

  username = "noib3";

  homeDirectory =
    if isDarwin then
      "/Users/${username}"
    else if isLinux then
      "/home/${username}"
    else
      throw "What's the home directory for this OS?";

  fuzzy-ripgrep = pkgs.writeShellScriptBin "fuzzy_ripgrep" (
    builtins.readFile "${configDir}/fzf/scripts/fuzzy-ripgrep.sh"
  );
in
{
  home = {
    inherit homeDirectory username;
    stateVersion = "22.11";
  };

  home.file.".mozilla/firefox/${username}/chrome" = {
    source = "${configDir}/firefox/chrome";
    recursive = true;
  };

  home.packages =
    with pkgs;
    [
      asciinema
      cmake
      delta
      dua
      fd
      fuzzy-ripgrep
      gh
      helix
      jq
      neovim
      # Needed by Copilot.
      nodejs
      (nerdfonts.override {
        fonts = [
          "FiraCode"
          "Inconsolata"
          "Iosevka"
          "SourceCodePro"
        ];
      })
      ookla-speedtest
      pfetch
      python312Packages.ipython
      ripgrep
      scripts.lf-recursive
      scripts.preview
      scripts.rg-pattern
      scripts.rg-preview
      spotify
      texliveConTeXt
      tokei
      tree
      unzip
      vimv
      zip
      zoom-us
    ]
    # Formatters.
    ++ [
      nixfmt-rfc-style
      stylua
    ]
    # LSP servers.
    ++ [
      marksman
      nil
      sumneko-lua-language-server
    ]
    ++ lib.lists.optionals isDarwin [
      coreutils
      findutils
      gnused
      libtool
    ]
    ++ lib.lists.optionals isLinux [
      blueman
      calcurse
      # Needed by Neovim to compile Tree-sitter grammars.
      clang
      (import "${configDir}/dmenu" {
        inherit
          pkgs
          colorscheme
          font-family
          palette
          hexlib
          ;
      })
      feh
      glibc
      glxinfo
      grimblast
      libnotify
      noto-fonts-emoji
      obs-studio
      playerctl
      pciutils # Contains lspci.
      pick-colour-picker
      signal-desktop
      wl-clipboard-rs
      wmctrl
      xclip
      xdotool
      xdg-utils
      xorg.xev
      xorg.xwininfo
      (pkgs.makeDesktopItem {
        name = "qutebrowser";
        desktopName = "qutebrowser";
        exec = "${pkgs.qutebrowser}/bin/qutebrowser";
        mimeTypes = [
          "text/html"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
        ];
        icon = "qutebrowser";
      })
    ]
    # Rust.
    ++ (
      let
        components = [
          "clippy"
          # Needed by `cargo-llvm-cov`.
          "llvm-tools"
          "rust-analyzer"
          # Needed by `rust-analyzer` to index `std`.
          "rust-src"
          "rustfmt"
        ];
      in
      [
        (rust-bin.selectLatestNightlyWith (
          toolchain: toolchain.minimal.override { extensions = components; }
        ))
        cargo-criterion
        cargo-deny
        cargo-expand
        cargo-flamegraph
        cargo-fuzz
        cargo-llvm-cov
      ]
    );

  home.pointerCursor = lib.mkIf isLinux {
    package = pkgs.vanilla-dmz;
    name = "Vanilla-DMZ";
    size = 16;
    x11.enable = true;
    x11.defaultCursor = "left_ptr";
  };

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
    OSFONTDIR = lib.strings.optionalString isLinux (
      config.home.homeDirectory + "/.nix-profile/share/fonts/truetype/NerdFonts"
    );
  };

  fonts.fontconfig = {
    enable = isLinux;
  };

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };

  nixpkgs.overlays = [
    # Pass `--ozone-platform=wayland` to Spotify, or it'll look blurry on
    # Wayland.
    (final: prev: {
      spotify = prev.spotify.overrideAttrs (oldAttrs: {
        postFixup =
          oldAttrs.postFixup or ""
          + ''
            wrapProgram $out/bin/spotify --add-flags "--ozone-platform=wayland"
          '';
      });
    })
  ];

  xdg.configFile = {
    "fd/ignore" = {
      source = "${configDir}/fd/ignore";
    };

    # Forcing an update w/ `fc-cache --really-force` may be needed on Linux.
    "fontconfig/fonts.conf" = {
      text = import "${configDir}/fontconfig/fonts.conf.nix" { fontFamily = font-family; };
    };

    "fusuma/config.yml" = lib.mkIf isLinux { source = "${configDir}/fusuma/config.yml"; };

    "nvim" = {
      source = "${configDir}/neovim";
      recursive = true;
    };
  };

  xdg.mimeApps = {
    enable = isLinux;
    defaultApplications = {
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
    };
  };

  programs.alacritty =
    {
      enable = true;
    }
    // (import "${configDir}/alacritty" {
      inherit font-family machine palette;
      inherit (lib.lists) optionals;
      inherit (lib.attrsets) optionalAttrs;
      inherit isDarwin isLinux;
      shell = {
        program = "${pkgs.fish}/bin/fish";
        args = [ "--interactive" ];
      };
    });

  programs.ags = import "${configDir}/ags" { inherit pkgs; };

  programs.bat = {
    enable = true;
  } // (import "${configDir}/bat");

  programs.direnv = {
    enable = true;
  } // (import "${configDir}/direnv");

  programs.fish =
    {
      enable = true;
    }
    // (import "${configDir}/fish" {
      inherit pkgs colorscheme palette;
      inherit (lib.strings) removePrefix;
      cloudDir = homeDirectory + "/Documents";
    });

  programs.firefox =
    {
      enable = true;
    }
    // (import "${configDir}/firefox" {
      inherit
        pkgs
        lib
        colorscheme
        font-family
        machine
        palette
        hexlib
        ;
    });

  programs.fzf =
    {
      enable = true;
    }
    // (import "${configDir}/fzf" {
      inherit
        pkgs
        colorscheme
        palette
        hexlib
        ;
      inherit (lib) concatStringsSep;
      inherit (lib.strings) removePrefix;
    });

  programs.git = {
    enable = true;
  } // (import "${configDir}/git" { inherit colorscheme; });

  programs.gpg = {
    enable = true;
  };

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
    enable = isLinux;
  } // (import "${configDir}/mpv");

  programs.qutebrowser =
    {
      enable = isLinux;
    }
    // (import "${configDir}/qutebrowser" {
      inherit
        pkgs
        colorscheme
        font-family
        palette
        hexlib
        ;
    });

  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.starship = {
    enable = true;
  } // (import "${configDir}/starship" { inherit (lib) concatStrings; });

  programs.vivid =
    {
      enable = true;
    }
    // (import "${configDir}/vivid" {
      inherit colorscheme palette;
      inherit (lib.strings) removePrefix;
    });

  programs.zathura = (
    {
      enable = isLinux;
    }
    // (import "${configDir}/zathura" {
      inherit
        colorscheme
        font-family
        palette
        hexlib
        ;
    })
  );

  # services.dunst = ({
  #   enable = isLinux;
  # } // (import "${configDir}/dunst" {
  #   inherit colorscheme font-family palette hexlib;
  #   inherit (pkgs) hicolor-icon-theme;
  # }));

  # services.fusuma = {
  #   enable = true;
  # } // (import "${configDir}/fusuma" {
  #   inherit pkgs;
  # });

  services.gpg-agent = (
    { enable = isLinux; } // (import "${configDir}/gpg/gpg-agent.nix" { inherit pkgs; })
  );

  services.mpris-proxy = {
    enable = isLinux;
  };

  # services.picom = ({
  #   enable = isLinux;
  # } // (import "${configDir}/picom"));
  #
  # services.polybar = ({
  #   enable = isLinux;
  #   package = pkgs.polybar.override {
  #     pulseSupport = true;
  #   };
  # } // (import "${configDir}/polybar" {
  #   inherit colorscheme font-family palette hexlib;
  #   inherit (lib) concatStringsSep;
  # }));

  # services.skhd = ({
  #   enable = isDarwin;
  # } // (import "${configDir}/skhd" {
  #   inherit pkgs;
  # }));

  services.ssh-agent = {
    enable = true;
  };

  # services.sxhkd = ({
  #   enable = isLinux;
  # } // (import "${configDir}/sxhkd" {
  #   inherit configDir;
  #   inherit (pkgs) writeShellScriptBin;
  #   inherit (pkgs.writers) writePython3Bin;
  # }));

  services.udiskie = ({ enable = isLinux; } // (import "${configDir}/udiskie"));

  services.wlsunset = ({ enable = isLinux; } // (import "${configDir}/wlsunset"));

  systemd.user.startServices = true;

  wayland.windowManager.hyprland = import "${configDir}/hyprland" { inherit pkgs; };

  # xsession = lib.mkIf isLinux ({
  #   enable = true;
  #
  #   windowManager.bspwm = {
  #     enable = true;
  #   } // (import "${configDir}/bspwm") {
  #     inherit pkgs colorscheme palette hexlib;
  #   };
  #
  #   profileExtra = ''
  #     ${pkgs.hsetroot}/bin/hsetroot \
  #       -solid "${hexlib.scale 0.75 palette.primary.background}"
  #   '';
  # });
}
