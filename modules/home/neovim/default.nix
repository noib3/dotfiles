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
      with pkgs;
      [
        neovim
      ]
      ++ lib.lists.optionals stdenv.isLinux [
        # Needed to compile Tree-sitter grammars.
        clang
      ];

    home.sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim +Man! -";
    };

    nixpkgs.overlays = [
      inputs.neovim-nightly-overlay.overlays.default
    ];

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
