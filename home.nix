{
  config,
  lib,
  pkgs,
  colorscheme,
  fonts,
  userName,
  ...
}:

let
  inherit (pkgs.stdenv) isDarwin isLinux;

  configDir = ./configs;

  configs = import "${configDir}" {
    inherit
      config
      lib
      pkgs
      colorscheme
      ;
    hexlib = import ./lib/hex.nix { inherit lib; };
    palette = import (./palettes + "/${colorscheme}.nix");
  };
in
{
  inherit fonts;

  home = {
    homeDirectory =
      if isDarwin then
        "/Users/${userName}"
      else if isLinux then
        "/home/${userName}"
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
        nixVersions.latest
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
        brewCasks.protonvpn
        coreutils
        gnused
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
      # Lua.
      ++ [
        stylua
        sumneko-lua-language-server
      ]
      # Markdown.
      ++ [ marksman ]
      # Nix.
      ++ [
        nil
        nixfmt-rfc-style
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
        ]
        # cargo-llvm-cov is currently broken on macOS.
        ++ lib.lists.optionals (!isDarwin) [ cargo-llvm-cov ]
      )
      # Typescript.
      ++ [
        prettierd
        typescript
        typescript-language-server
      ];

    pointerCursor = lib.mkIf isLinux {
      package = pkgs.vanilla-dmz;
      name = "Vanilla-DMZ";
      size = 16;
    };

    sessionVariables = {
      CARGO_HOME = "${config.xdg.dataHome}/cargo";
      EDITOR = "nvim";
      MANPAGER = "nvim +Man! -";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      COLORTERM = "truecolor";
      LS_COLORS = "$(vivid generate current)";
      LF_ICONS = (builtins.readFile "${configDir}/lf/LF_ICONS");
      HISTFILE = "${config.xdg.cacheHome}/bash/bash_history";
      LESSHISTFILE = "${config.xdg.cacheHome}/less/lesshst";
      OSFONTDIR = lib.strings.optionalString isLinux (
        config.home.homeDirectory + "/.nix-profile/share/fonts/truetype/NerdFonts"
      );
    };

    stateVersion = "22.11";

    username = userName;
  };

  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-substituters = [
        "https://cache.soopy.moe"
        "https://nix-community.cachix.org"
      ];
      warn-dirty = false;
    };
  };

  programs = {
    inherit (configs)
      ags
      alacritty
      bat
      direnv
      fd
      fish
      fuzzel
      fzf
      git
      gpg
      home-manager
      lazygit
      lf
      mpv
      nix-index
      qutebrowser
      ripgrep
      starship
      vivid
      zathura
      ;
  };

  services = {
    bluetooth-autoconnect = {
      enable = isLinux;
    };
    inherit (configs)
      fusuma
      gpg-agent
      kanshi
      mpris-proxy
      ssh-agent
      udiskie
      wlsunset
      ;
  };

  systemd.user.startServices = true;

  wayland.windowManager.hyprland = configs.hyprland;

  xdg = {
    configFile = {
      "nvim" = {
        source = "${configDir}/neovim";
        recursive = true;
      };
    };

    dataFile = {
      "cargo/config.toml" = {
        text = configs.cargo.configDotToml;
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
