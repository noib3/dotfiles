{
  inputs,
  lib,
  stdenvNoCC,
  vimPlugins,
  writeShellApplication,
  writeTextDir,
  includeConfig ? true,
  palette ? import ../palettes/gruvbox.nix,
}:

let
  # Converts a Nix value to a Lua value.
  toLua =
    value:
    if builtins.isAttrs value then
      value
      |> lib.mapAttrsToList (k: v: "${k} = ${toLua v}")
      |> builtins.concatStringsSep ", "
      |> (str: "{ ${str} }")
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

  # Vim plugins added to the rtp.
  nixPlugins = [
    inputs.blink-cmp.packages.${stdenvNoCC.system}.default
    inputs.blink-emoji-nvim
    inputs.bufdelete-nvim
    inputs.colorful-menu-nvim
    inputs.comment-nvim
    inputs.conform-nvim
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
    inputs.nvim-lspconfig
    inputs.nvim-nio
    inputs.nvim-notify
    inputs.nvim-surround
    inputs.nvim-treesitter
    inputs.nvim-treesitter-endwise
    inputs.nvim-ts-context-commentstring
    inputs.nvim-web-devicons
    inputs.plenary-nvim
    inputs.rustaceanvim
    inputs.toggleterm-nvim
    inputs.tokyonight-nvim
    inputs.treesitter-modules-nvim
    inputs.trouble-nvim
  ];

  # Each of these is a valid Neovim rtp entry.
  plugins =
    # The config directory is first so that its `lua/` modules take priority,
    # matching Neovim's default behavior of placing `stdpath('config')` at the
    # top of the rtp.
    lib.optionals includeConfig [ ../config ]
    ++ nixPlugins
    ++ treeSitterParsers
    ++ treeSitterQueries
    ++ [ (writeTextDir "lua/palette.lua" "return ${toLua palette}") ];

  neovimOrig = inputs.nix-community-neovim.packages.${stdenvNoCC.system}.default;

  neovimWithPlugins = writeShellApplication {
    name = "nvim-with-plugins";
    text = ''
      exec ${lib.getExe neovimOrig} \
        ${lib.optionalString includeConfig "-u ${../config/init.lua}"} \
        --cmd 'set rtp^=${lib.concatStringsSep "," plugins}' \
        "$@"
    '';
  };
in
writeShellApplication {
  name = "nvim";
  runtimeEnv.NVIM_EXE = lib.getExe neovimWithPlugins;
  text = builtins.readFile ./nvim.sh;
}
