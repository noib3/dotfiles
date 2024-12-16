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

    xdg.configFile.nvim = {
      source = config.lib.file.mkOutOfStoreSymlink (config.lib.mine.mkAbsolute ./.);
    };
  };
}
