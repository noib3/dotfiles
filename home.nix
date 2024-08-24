{
  config,
  lib,
  pkgs,
  colorscheme,
  fonts,
  username,
  ...
}:

let
  inherit (pkgs.stdenv) isDarwin isLinux;

  configs = ./home;
  hexlib = import ./lib/hex.nix { inherit (pkgs) lib; };
  palette = import (./palettes + "/${colorscheme}.nix");
in
{
  inherit fonts;

  home = {
    inherit username;

    homeDirectory =
      if isDarwin then
        "/Users/${username}"
      else if isLinux then
        "/home/${username}"
      else
        throw "What's the home directory for this OS?";

    packages =
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
      ++ lib.lists.optionals isDarwin [
        coreutils
        findutils
        gnused
        libtool
      ]
      ++ lib.lists.optionals isLinux [
        cameractrls
        clang # Needed by Neovim to compile Tree-sitter grammars.
        feh
        glxinfo
        grimblast
        libnotify
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

    pointerCursor = lib.mkIf isLinux {
      package = pkgs.vanilla-dmz;
      name = "Vanilla-DMZ";
      size = 16;
    };

    sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim +Man! -";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      COLORTERM = "truecolor";
      LS_COLORS = "$(vivid generate current)";
      LF_ICONS = (builtins.readFile "${configs}/lf/LF_ICONS");
      HISTFILE = "${config.xdg.cacheHome}/bash/bash_history";
      LESSHISTFILE = "${config.xdg.cacheHome}/less/lesshst";
      RIPGREP_CONFIG_PATH = "${configs}/ripgrep/ripgreprc";
      OSFONTDIR = lib.strings.optionalString isLinux (
        config.home.homeDirectory + "/.nix-profile/share/fonts/truetype/NerdFonts"
      );
    };

    stateVersion = "22.11";
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

  programs = {
    ags = import "${configs}/ags" { inherit pkgs; };
    bat = import "${configs}/bat";
    direnv = import "${configs}/direnv";
    fd = import "${configs}/fd";
    fuzzel = import "${configs}/fuzzel" { inherit pkgs; };
    gpg = import "${configs}/gpg";
    home-manager = import "${configs}/home-manager";
    lazygit = import "${configs}/lazygit";
    lf = import "${configs}/lf" { inherit pkgs; };
    mpv = import "${configs}/mpv" { inherit pkgs; };
    nix-index = import "${configs}/nix-index";
  };

  programs.alacritty =
    {
      enable = true;
    }
    // (import "${configs}/alacritty" {
      inherit config palette;
      inherit (lib.lists) optionals;
      inherit (lib.attrsets) optionalAttrs;
      inherit isDarwin isLinux;
      shell = {
        program = "${pkgs.fish}/bin/fish";
        args = [ "--interactive" ];
      };
    });

  programs.fish =
    {
      enable = true;
    }
    // (import "${configs}/fish" {
      inherit pkgs colorscheme palette;
      inherit (lib.strings) removePrefix;
      cloudDir = config.home.homeDirectory + "/Documents";
    });

  programs.fzf =
    {
      enable = true;
    }
    // (import "${configs}/fzf" {
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
  } // (import "${configs}/git" { inherit colorscheme; });

  programs.qutebrowser =
    {
      enable = isLinux;
    }
    // (import "${configs}/qutebrowser" {
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
  } // (import "${configs}/starship" { inherit (lib) concatStrings; });

  programs.vivid =
    {
      enable = true;
    }
    // (import "${configs}/vivid" {
      inherit colorscheme palette;
      inherit (lib.strings) removePrefix;
    });

  programs.zathura = (
    {
      enable = isLinux;
    }
    // (import "${configs}/zathura" {
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
      enable = isLinux;
    };
    # dunst = {
    #     enable = isLinux;
    # };
    fusuma = import "${configs}/fusuma" { inherit pkgs; };
    mpris-proxy = {
      enable = isLinux;
    };
    gpg-agent = import "${configs}/gpg/gpg-agent.nix" { inherit pkgs; };
    ssh-agent = {
      enable = true;
    };
    udiskie = import "${configs}/udiskie" { inherit pkgs; };
    wlsunset = import "${configs}/wlsunset" { inherit pkgs; };
  };

  systemd.user.startServices = true;

  wayland.windowManager.hyprland = import "${configs}/hyprland" { inherit pkgs; };

  xdg = {
    configFile = {
      "nvim" = {
        source = "${configs}/neovim";
        recursive = true;
      };
    };

    mimeApps = {
      enable = isLinux;
      defaultApplications = {
        "application/pdf" = [ "org.pwmt.zathura.desktop" ];
        "text/html" = [ "qutebrowser.desktop" ];
        "x-scheme-handler/http" = [ "qutebrowser.desktop" ];
        "x-scheme-handler/https" = [ "qutebrowser.desktop" ];
      };
    };
  };
}
