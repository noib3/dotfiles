{
  lib,
  stdenvNoCC,
  writeShellApplication,
  writeTextDir,
  inputs,
  vimPlugins,
  palette ? import ./palettes/gruvbox.nix,
  includeConfig ? true,
  extraTreesitterParsers ? [ ],
  extraTreesitterQueries ? [ ],
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

  defaultParsers = with vimPlugins.nvim-treesitter-parsers; [
    c
    cpp
    lua
    markdown
    markdown_inline
    toml
    vimdoc
  ];

  defaultQueries = with vimPlugins.nvim-treesitter.queries; [
    c
    cpp
    lua
    markdown
    markdown_inline
    toml
    vimdoc
  ];

  # Each of these is a valid Neovim rtp entry.
  plugins =
    defaultParsers
    ++ defaultQueries
    ++ extraTreesitterParsers
    ++ extraTreesitterQueries
    ++ [ (writeTextDir "lua/palette.lua" "return ${toLua palette}") ]
    ++ lib.optionals includeConfig [ ./config ];

  neovimOrig = inputs.nix-community-neovim.packages.${stdenvNoCC.system}.default;

  neovimWithPlugins = writeShellApplication {
    name = "nvim-with-plugins";
    text = ''
      exec ${lib.getExe neovimOrig} \
        --cmd 'set rtp^=${lib.concatStringsSep "," (map toString plugins)}' \
        "$@"
    '';
  };
in
writeShellApplication {
  name = "nvim";
  runtimeEnv.NVIM_EXE = lib.getExe neovimWithPlugins;
  text = builtins.readFile ./nvim.sh;
}
