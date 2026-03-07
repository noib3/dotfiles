{
  lib,
  stdenvNoCC,
  writeShellApplication,
  neovim,
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

  parserLanguage =
    parser:
    if parser ? grammarName then
      parser.grammarName
    else
      throw "Expected parser package with `grammarName` attribute";

  queryLanguage =
    query:
    if query ? language then
      query.language
    else if query ? passthru && query.passthru ? language then
      query.passthru.language
    else
      throw "Expected query package with `language` attribute";

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

  allParsers = defaultParsers ++ extraTreesitterParsers;
  allQueries = defaultQueries ++ extraTreesitterQueries;

  configDir = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./plugin
      ./filetype.lua
      ./lua
      ./after
      ./lsp
      ./lazy-lock.json
    ];
  };

  dataDir = stdenvNoCC.mkDerivation {
    name = "nvim-data";
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/nvim/site/lua/generated
      echo "return ${toLua palette}" > $out/nvim/site/lua/generated/palette.lua

      mkdir -p $out/nvim/site/parser
      ${lib.concatMapStringsSep "\n" (
        parser:
        let
          lang = parserLanguage parser;
        in
        "ln -s ${parser}/parser/${lang}.so $out/nvim/site/parser/${lang}.so"
      ) allParsers}

      mkdir -p $out/nvim/site/queries
      ${lib.concatMapStringsSep "\n" (
        query:
        let
          lang = queryLanguage query;
        in
        "ln -s ${query}/queries/${lang} $out/nvim/site/queries/${lang}"
      ) allQueries}
    '';
  };

  # The config directory is appended (not prepended) to the runtime path so
  # that its plugin/ files are sourced after all other plugins.
  configRtpCmd = lib.optionalString includeConfig " --cmd 'set rtp+=${configDir}'";

  wrappedNeovim = lib.getExe (writeShellApplication {
    name = "nvim-wrapped";
    text = ''
      exec ${lib.getExe neovim} \
        --cmd 'set rtp^=${dataDir}/nvim/site'${configRtpCmd} \
        "$@"
    '';
  });
in
writeShellApplication {
  name = "nvim";
  runtimeEnv = {
    NVIM_EXE = wrappedNeovim;
  };
  text = builtins.readFile ./nvim.sh;
}
