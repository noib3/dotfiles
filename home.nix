{
  config,
  lib,
  pkgs,
  colorscheme,
  fontFamily,
  ...
}:

let
  inherit (pkgs.stdenv) isDarwin isLinux;

  configDir = ./home;

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
in
{
  inherit fontFamily;

  home = {
    inherit homeDirectory username;
    stateVersion = "22.11";
  };

  home.packages =
    with pkgs;
    [
      asciinema
      delta
      dua
      gh
      helix
      jq
      neovim
      nodejs # Needed by Copilot.
      ookla-speedtest
      pfetch
      python312Packages.ipython
      ripgrep
      scripts.fuzzy-ripgrep
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
      cameractrls
      clang # Needed by Neovim to compile Tree-sitter grammars.
      feh
      glxinfo
      grimblast
      libnotify
      noto-fonts-emoji
      obs-studio
      pciutils # Contains lspci.
      pick-colour-picker
      playerctl
      proton-pass
      protonvpn-cli_2
      signal-desktop
      wl-clipboard-rs
      xdg-utils
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

  xdg.configFile = {
    # Forcing an update w/ `fc-cache --really-force` may be needed on Linux.
    "fontconfig/fonts.conf" = {
      text = import "${configDir}/fontconfig/fonts.conf.nix" { inherit config; };
    };

    "nvim" = {
      source = "${configDir}/neovim";
      recursive = true;
    };
  };

  xdg.mimeApps = {
    enable = isLinux;
    defaultApplications = {
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "text/html" = [ "qutebrowser.desktop" ];
      "x-scheme-handler/http" = [ "qutebrowser.desktop" ];
      "x-scheme-handler/https" = [ "qutebrowser.desktop" ];
    };
  };

  programs.alacritty =
    {
      enable = true;
    }
    // (import "${configDir}/alacritty" {
      inherit config palette;
      inherit (lib.lists) optionals;
      inherit (lib.attrsets) optionalAttrs;
      inherit isDarwin isLinux;
      shell = {
        program = "${pkgs.fish}/bin/fish";
        args = [ "--interactive" ];
      };
    });

  programs = {
    ags = import "${configDir}/ags" { inherit pkgs; };
    bat = import "${configDir}/bat";
    direnv = import "${configDir}/direnv";
    fd = import "${configDir}/fd";
    fuzzel = import "${configDir}/fuzzel" { inherit pkgs; };
    gpg = import "${configDir}/gpg";
    home-manager = import "${configDir}/home-manager";
    lazygit = import "${configDir}/lazygit";
    lf = import "${configDir}/lf" { inherit pkgs; };
    mpv = import "${configDir}/mpv" { inherit pkgs; };
    nix-index = import "${configDir}/nix-index";
  };

  programs.fish =
    {
      enable = true;
    }
    // (import "${configDir}/fish" {
      inherit pkgs colorscheme palette;
      inherit (lib.strings) removePrefix;
      cloudDir = homeDirectory + "/Documents";
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

  programs.qutebrowser =
    {
      enable = isLinux;
    }
    // (import "${configDir}/qutebrowser" {
      inherit
        config
        pkgs
        colorscheme
        palette
        hexlib
        ;
    });

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
        config
        colorscheme
        palette
        hexlib
        ;
    })
  );

  services = {
    bluetooth-autoconnect = {
      enable = true;
    };
  };

  # services.dunst = ({
  #   enable = isLinux;
  # } // (import "${configDir}/dunst" {
  #   inherit colorscheme font-family palette hexlib;
  #   inherit (pkgs) hicolor-icon-theme;
  # }));

  # services.fusuma = import "${configDir}/fusuma" { inherit pkgs; };

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
}
