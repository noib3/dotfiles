{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.modules.neovim;
in
{
  options.modules.neovim = {
    enable = mkEnableOption "Neovim";
  };

  config = mkIf cfg.enable {
    home.packages =
      let
        # The Tree-sitter CLI needs a C compiler to build parsers.
        wrappedTreeSitter = pkgs.tree-sitter.overrideAttrs (oldAttrs: {
          nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
          postFixup = (oldAttrs.postFixup or "") + ''
            wrapProgram $out/bin/tree-sitter \
              --prefix PATH : ${lib.makeBinPath [ pkgs.clang ]}
          '';
        });

        unwrappedNeovim =
          inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.system}.default;
      in
      [
        # Wrap Neovim to add a bunch of runtime dependencies needed for various
        # plugins to work properly.
        (pkgs.symlinkJoin {
          name = "neovim-nightly-wrapped";
          paths = [ unwrappedNeovim ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/nvim \
              --prefix PATH : ${
                lib.makeBinPath [
                  # Needed by Copilot.
                  pkgs.nodejs
                  # Needed by nvim-treesitter to compile parsers.
                  wrappedTreeSitter
                ]
              }
          '';
        })
      ];

    home.sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim +Man! -";
    };

    xdg.configFile.nvim = {
      source = config.lib.file.mkOutOfStoreSymlink (config.lib.mine.mkAbsolute ./.);
    };

    xdg.dataFile."nvim/site/lua/generated/palette.lua" =
      let
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
            builtins.toString value;

        inherit (config.modules) colorscheme;
      in
      {
        text = "return ${toLua colorscheme.palette}";
      };
  };
}
