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

  # The Tree-sitter CLI needs a C compiler to build parsers.
  tree-sitter-wrapped = pkgs.symlinkJoin {
    name = "tree-sitter-wrapped";
    paths = [ pkgs.tree-sitter ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/tree-sitter \
        --prefix PATH : ${lib.makeBinPath [ pkgs.clang ]}
    '';
  };

  # Wrap Neovim to add a bunch of runtime dependencies needed for various
  # plugins to work properly.
  neovim-wrapped = pkgs.symlinkJoin {
    name = "neovim-nightly-wrapped";
    paths = [ inputs.neovim-nightly.packages.${pkgs.stdenv.system}.default ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nvim \
        --prefix PATH : ${
          lib.makeBinPath [
            # Needed by nvim-treesitter to compile parsers.
            tree-sitter-wrapped
          ]
        }
    '';
  };
in
{
  options.modules.neovim = {
    enable = mkEnableOption "Neovim";
  };

  config = mkIf cfg.enable {
    home.packages = [ neovim-wrapped ];

    home.sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim +Man! -";
    };

    modules.nixpkgs.allowUnfreePackages = [
      "copilot-language-server"
    ];

    xdg.configFile.nvim = {
      source = config.lib.file.mkOutOfStoreSymlink (config.lib.mine.mkAbsolute ./.);
    };

    xdg.dataFile."nvim/site/lua/generated/palette.lua".text =
      "return ${toLua config.modules.colorscheme.palette}";

    xdg.dataFile."nvim/site/lua/generated/tools.lua".text = ''
      return {
        copilot = "${lib.getExe pkgs.copilot-language-server}";
      }
    '';
  };
}
