{
  config,
  lib,
  pkgs,
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

  home = {
    homeDirectory =
      let
        inherit (config.home) username;
      in
      if isDarwin then
        "/Users/${username}"
      else if isLinux then
        "/home/${username}"
      else
        throw "What's the home directory for this OS?";

    # Disable the "Last login: ..." message when opening terminals.
    file.".hushlogin".text = "";

    packages =
      with pkgs;
      [
        asciinema
        cachix
        delta
        dua
        gh
        helix
        jq
        ookla-speedtest
        pfetch
        python312Packages.ipython
        ripgrep
        scripts.fuzzy-ripgrep
        scripts.lf-recursive
        scripts.preview
        scripts.rg-pattern
        scripts.rg-preview
        scripts.td
        texliveConTeXt
        tokei
        tree
        unzip
        vimv
        zip
        zoom-us
      ]
      ++ lib.lists.optionals isDarwin [
        brewCasks.obs
        brewCasks.protonvpn
        coreutils
        gnused
        iina
        keycastr
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
        wl-clipboard-rs
        xdg-utils
      ]
      # Lua.
      ++ [
        stylua
        lua-language-server
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
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 18;
      dotIcons.enable = false;
    };

    sessionVariables = {
      COLORTERM = "truecolor";
      DOCUMENTS = config.lib.mine.documentsDir;
      HISTFILE = "${config.xdg.cacheHome}/bash/bash_history";
      IPYTHONDIR = "${config.xdg.configHome}/ipython";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      LESSHISTFILE = "${config.xdg.cacheHome}/less/lesshst";
      LF_ICONS = (builtins.readFile "${configDir}/lf/LF_ICONS");
      OSFONTDIR = lib.strings.optionalString isLinux (
        config.home.homeDirectory + "/.nix-profile/share/fonts/truetype/NerdFonts"
      );
      TEXMFCONFIG = "${config.xdg.configHome}/texmf";
      TEXMFVAR = "${config.xdg.stateHome}/texmf";
    };

    stateVersion = "25.11";
  };

  modules = {
    bettermouse.enable = isDarwin;
    brave.enable = isDarwin;
    claude.enable = true;
    codex.enable = true;
    fish.enable = true;
    ghostty.enable = true;
    git.enable = true;
    gnupg.enable = true;
    hyprland.enable = isLinux;
    kubectl.enable = true;
    macosDefaults.enable = isDarwin;
    macOSPreferences.enable = isDarwin;
    macOSProfile.enable = isDarwin;
    neovim.enable = true;
    opencode.enable = true;
    proton-drive.enable = isDarwin;
    rust.enable = true;
    selfcontrol.enable = isDarwin;
    signal.enable = true;
    skhd.enable = isDarwin;
    snowstorm-work.enable = true;
    ssh.enable = true;
    starship.enable = true;
    terminfo.enable = true;
    udiskie.enable = isLinux;
    whatsapp.enable = isDarwin;
    yabai.enable = isDarwin;
  };

  programs = {
    inherit (configs)
      bat
      direnv
      fd
      fuzzel
      fzf
      home-manager
      lazygit
      lf
      mpv
      nix-index
      qutebrowser
      ripgrep
      zathura
      ;
  };

  services = {
    bluetooth-autoconnect = {
      enable = isLinux;
    };
    inherit (configs)
      kanshi
      mpris-proxy
      wlsunset
      ;
  };

  systemd.user.startServices = true;

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
