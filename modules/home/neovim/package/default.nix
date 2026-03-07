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
  vimPlugins = [
    inputs.bufdelete-nvim
    inputs.nvim-lspconfig
    inputs.nvim-ts-context-commentstring
    inputs.comment-nvim
    inputs.crates-nvim
    inputs.gitsigns-nvim
    inputs.inc-rename-nvim
    inputs.lsp-progress-nvim
    inputs.neotab-nvim
    inputs.nvim-lastplace
    inputs.nvim-surround
    inputs.conform-nvim
    inputs.hop-nvim
    inputs.nvim-colorizer-lua
    inputs.nvim-notify
    inputs.nvim-web-devicons
  ];

  # Each of these is a valid Neovim rtp entry.
  plugins =
    # The config directory is first so that its `lua/` modules take priority,
    # matching Neovim's default behavior of placing `stdpath('config')` at the
    # top of the rtp.
    lib.optionals includeConfig [ ../config ]
    ++ vimPlugins
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
