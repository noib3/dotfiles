{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv) isDarwin isLinux;
  inherit (config.machines.current) isHeadless;
in
{
  # Import all the modules in this directory.
  imports =
    builtins.readDir ./.
    |> lib.filterAttrs (name: type: type == "directory")
    |> builtins.attrNames
    |> map (dirName: ./. + "/${dirName}");

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
        delta
        dua
        gh
        helix
        jq
        ookla-speedtest
        pfetch
        python312Packages.ipython
        ripgrep
        tokei
        tree
        unzip
        vimv
        zip
      ]
      ++ lib.lists.optionals (!isHeadless) [
        asciinema
        signal-desktop
        zoom-us
      ]
      ++ lib.lists.optionals isDarwin [
        brewCasks.obs
        coreutils
        gnused
        iina
        keycastr
      ]
      ++ lib.lists.optionals isLinux [
        pciutils # Contains lspci.
        proton-vpn-cli
        wl-clipboard-rs
        xdg-utils
      ]
      ++ lib.lists.optionals (isLinux && !isHeadless) [
        grimblast
        libnotify
        obs-studio
        pick-colour-picker
        playerctl
        proton-pass
      ]
      # C/C++.
      ++ [ clang-tools ]
      # Lua.
      ++ [
        lua-language-server
        stylua
      ]
      # Markdown.
      ++ [ marksman ]
      # Shell.
      ++ [
        bash-language-server
        shellcheck
        shfmt
      ]
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
      ANDROID_USER_HOME = "${config.xdg.dataHome}/android";
      COLORTERM = "truecolor";
      DOCUMENTS = config.lib.mine.documentsDir;
      GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";
      HISTFILE = "${config.xdg.cacheHome}/bash/bash_history";
      IPYTHONDIR = "${config.xdg.configHome}/ipython";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      LESSHISTFILE = "${config.xdg.cacheHome}/less/lesshst";
      NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
      TEXMFCONFIG = "${config.xdg.configHome}/texmf";
      TEXMFVAR = "${config.xdg.stateHome}/texmf";
    }
    // (lib.optionalAttrs isLinux {
      OSFONTDIR = "${config.home.profileDirectory}/share/fonts/truetype/NerdFonts";
    });

    stateVersion = "25.11";
  };

  modules = {
    bat.enable = true;
    claude.enable = true;
    codex.enable = true;
    delete-ds-store.enable = isDarwin;
    direnv.enable = true;
    fd.enable = true;
    fish.enable = true;
    fzf.enable = true;
    gc-git-repos.enable = true;
    git.enable = true;
    gnupg.enable = true;
    home-manager.enable = true;
    kubectl.enable = true;
    lazygit.enable = true;
    lf.enable = true;
    lima.enable = isDarwin;
    macOSPreferences.enable = isDarwin;
    macOSProfile.enable = isDarwin;
    macosDefaults.enable = isDarwin;
    neovim.enable = true;
    opencode.enable = true;
    ripgrep.enable = true;
    rust.enable = true;
    snowstorm-work.enable = true;
    ssh.enable = true;
    starship.enable = true;
    terminfo.enable = true;
  }
  // lib.optionalAttrs (!isHeadless) {
    bettermouse.enable = isDarwin;
    brave.enable = isDarwin;
    ghostty.enable = true;
    hyprland.enable = isLinux;
    kanshi.enable = isLinux;
    mpv.enable = isLinux;
    proton-drive.enable = isDarwin;
    qutebrowser.enable = isLinux;
    selfcontrol.enable = isDarwin;
    skhd.enable = isDarwin;
    whatsapp.enable = isDarwin;
    wlsunset.enable = isLinux;
    yabai.enable = isDarwin;
    zathura.enable = isLinux;
  };

  services = {
    mpris-proxy.enable = isLinux && !isHeadless;
  };

  systemd.user.startServices = true;

  xdg = {
    enable = true;
    mimeApps.enable = isLinux && !isHeadless;
  };
}
