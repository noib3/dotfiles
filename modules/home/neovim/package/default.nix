{
  lib,
  linkFarm,
  runCommandLocal,
  stdenvNoCC,
  writeTextDir,
  copilot-language-server,
  pkgs,
  vimPlugins,
  # --
  inputs,
  includeConfig ? true,
  paletteData ? import ../palettes/gruvbox.nix,
}:

let
  # Converts a Nix value to a Lua value.
  toLua =
    value:
    if builtins.isAttrs value then
      let
        attrs = lib.mapAttrsToList (k: v: "${k} = ${toLua v}") value;
      in
      "{ ${builtins.concatStringsSep ", " attrs} }"
    else if builtins.isString value then
      "'${value}'"
    else
      toString value;

  treeSitterParsers = with vimPlugins.nvim-treesitter-parsers; [
    c
    cpp
    css
    html
    javascript
    jsdoc
    lua
    markdown
    markdown_inline
    nix
    rust
    scss
    svelte
    toml
    typescript
    vimdoc
  ];

  treeSitterQueries = with vimPlugins.nvim-treesitter.queries; [
    c
    cpp
    css
    ecma
    html
    html_tags
    javascript
    jsdoc
    jsx
    lua
    markdown
    markdown_inline
    nix
    rust
    scss
    svelte
    toml
    typescript
    vimdoc
  ];

  codediff-nvim = pkgs.stdenv.mkDerivation {
    pname = "codediff.nvim";
    version = lib.trim (builtins.readFile "${inputs.codediff-nvim}/VERSION");
    src = inputs.codediff-nvim;

    nativeBuildInputs = [ pkgs.cmake ];

    buildInputs =
      lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.llvmPackages.openmp ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.stdenv.cc.cc.lib ];

    configurePhase = ''
      runHook preConfigure
      cmake -B build -S .
      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
      cmake --build build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -R . "$out"
      rm -rf "$out/build"
      runHook postInstall
    '';
  };

  localPlugins = lib.mapAttrsToList (name: _: ../plugins + "/${name}") (
    builtins.readDir ../plugins
  );

  # Each of these is a valid Neovim rtp entry.
  plugins = [
    inputs.blink-cmp.packages.${stdenvNoCC.system}.default
    inputs.blink-cmp.inputs.blink-lib.packages.${stdenvNoCC.system}.default
    inputs.blink-emoji-nvim
    inputs.bufdelete-nvim
    codediff-nvim
    inputs.colorful-menu-nvim
    inputs.comment-nvim
    inputs.conform-nvim
    inputs.copilot-lua
    inputs.crates-nvim
    inputs.fzf-lua
    inputs.gitsigns-nvim
    inputs.gruvbox-nvim
    inputs.hop-nvim
    inputs.inc-rename-nvim
    inputs.incline-nvim
    inputs.lsp-progress-nvim
    inputs.lualine-nvim
    inputs.neotab-nvim
    inputs.neotest
    inputs.nvim-autopairs
    inputs.nvim-colorizer-lua
    inputs.nvim-lastplace
    inputs.nvim-lint
    inputs.nvim-lspconfig
    inputs.nvim-nio
    inputs.nvim-notify
    inputs.nvim-surround
    inputs.nvim-treesitter
    inputs.nvim-treesitter-endwise
    inputs.nvim-web-devicons
    inputs.plenary-nvim
    inputs.rustaceanvim
    inputs.toggleterm-nvim
    inputs.tokyonight-nvim
    inputs.treesitter-modules-nvim
    inputs.trouble-nvim
  ]
  ++ localPlugins
  ++ treeSitterParsers
  ++ treeSitterQueries
  ++ [ (writeTextDir "lua/palette.lua" "return ${toLua paletteData}") ];

  env = {
    COPILOT_SERVER_PATH = lib.getExe copilot-language-server;
    # The plugins' `lua` directories merged into a single tree, used by EmmyLua
    # to resolve plugin type definitions. EmmyLua names modules by their path
    # relative to a library root, so the root has to be where `require()`
    # starts looking.
    NVIM_PLUGINS_LUA = runCommandLocal "nvim-plugins-lua" { } ''
      mkdir -p "$out"
      for plugin in ${lib.escapeShellArgs plugins}; do
        if [ -d "$plugin/lua" ]; then
          cp -rs --no-preserve=mode "$plugin/lua/." "$out/"
        fi
      done
    '';
    XDG_DATA_DIRS = linkFarm "nvim-site" (
      builtins.map (
        plugin:
        let
          name = builtins.baseNameOf (builtins.unsafeDiscardStringContext plugin);
        in
        {
          name = "nvim/site/pack/noib3/start/${name}";
          path = plugin;
        }
      ) plugins
    );
  }
  // lib.optionalAttrs includeConfig {
    XDG_CONFIG_HOME = runCommandLocal "nvim-config-home" { } ''
      mkdir -p "$out"
      ln -s ${../config} "$out/nvim"
    '';
  };

  neovim = import ./neovim.nix {
    inherit inputs lib pkgs;
  };
in
pkgs.symlinkJoin {
  name = "nvim";
  paths = [ neovim ];
  nativeBuildInputs = [ pkgs.makeWrapper ];

  postBuild =
    let
      envWrapperArgs = lib.escapeShellArgs (
        lib.concatLists (
          lib.mapAttrsToList (name: value: [
            "--set"
            name
            value
          ]) env
        )
      );
    in
    ''
      wrapProgram "$out/bin/nvim" ${envWrapperArgs}
    '';

  passthru = {
    inherit env neovim;
  };

  meta.mainProgram = "nvim";
}
