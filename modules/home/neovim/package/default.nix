{
  coreutils,
  lib,
  linkFarm,
  runCommandLocal,
  stdenvNoCC,
  writeShellApplication,
  writeTextDir,
  copilot-language-server,
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
    lua
    markdown
    markdown_inline
    nix
    rust
    toml
    vimdoc
  ];

  treeSitterQueries = with vimPlugins.nvim-treesitter.queries; [
    c
    cpp
    lua
    markdown
    markdown_inline
    nix
    rust
    toml
    vimdoc
  ];

  # Each of these is a valid Neovim rtp entry.
  plugins = [
    inputs.blink-cmp.packages.${stdenvNoCC.system}.default
    inputs.blink-emoji-nvim
    inputs.bufdelete-nvim
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
    inputs.nomad.packages.${stdenvNoCC.system}.neovim-nightly
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
  ++ treeSitterParsers
  ++ treeSitterQueries
  ++ [ (writeTextDir "lua/palette.lua" "return ${toLua paletteData}") ];

  # A directory containing one symlink per plugin, used by lua-language-server
  # to resolve plugin type definitions.
  pluginsDir = linkFarm "nvim-plugins" (
    builtins.map (plugin: {
      name = builtins.baseNameOf (builtins.unsafeDiscardStringContext plugin);
      path = plugin;
    }) plugins
  );

  env = {
    COPILOT_SERVER_PATH = lib.getExe copilot-language-server;
    NVIM_PLUGINS = pluginsDir;
    XDG_DATA_DIRS = runCommandLocal "nvim-site" { } ''
      mkdir -p "$out/nvim/site/pack/noib3/start"
      ln -s ${pluginsDir}/* "$out/nvim/site/pack/noib3/start/"
    '';
  }
  // lib.optionalAttrs includeConfig {
    XDG_CONFIG_HOME = runCommandLocal "nvim-config-home" { } ''
      mkdir -p "$out"
      ln -s ${../config} "$out/nvim"
    '';
  };
in
writeShellApplication {
  name = "nvim";
  runtimeInputs = [
    coreutils
  ];
  runtimeEnv = env // {
    NVIM_EXE =
      lib.getExe
        inputs.nix-community-neovim.packages.${stdenvNoCC.system}.default;
  };
  passthru = { inherit env; };
  text = builtins.readFile ./nvim.sh;
}
