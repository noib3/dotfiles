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
    inherit config lib pkgs;
  };
in
{
  imports = [
    ./modules/home
  ];

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
      # TOML.
      ++ [
        (taplo.override { withLsp = true; })
      ]
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

  modules = {
    astal.enable = isLinux;
    brave.enable = isDarwin;
    colorscheme.${colorscheme}.enable = true;
    dropbox.enable = true;
    neovim.enable = true;
    rust.enable = true;
    ssh.enable = true;
    terminfo.enable = true;
    udiskie.enable = isLinux;
  };

  programs = {
    inherit (configs)
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
      wlsunset
      ;
  };

  systemd.user.startServices = true;

  wayland.windowManager.hyprland = configs.hyprland;

  xdg = {
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
