{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.modules.neovim;
in
{
  imports = [
    inputs.neovim.homeManagerModules.default
  ];

  options.modules.neovim = {
    enable = lib.mkEnableOption "Neovim";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      config.modules.neovim.package
    ];

    home.sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim +Man! -";
    };

    modules.neovim = {
      includeConfig = false;
      palette = config.modules.colorscheme.palette;
    };

    xdg.configFile.nvim = {
      source = config.lib.file.mkOutOfStoreSymlink (config.lib.mine.mkAbsolute ./.);
    };
  };
}
