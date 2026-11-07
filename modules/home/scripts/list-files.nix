{
  config,
  pkgs,
}:

let
  inherit (config.lib.mine) hex;
  inherit (config.modules.colorschemes) name palette;
in
pkgs.writeShellApplication {
  name = "list-files";

  runtimeInputs = with pkgs; [
    config.modules.scripts.frecency
    fd
    gawk
    gnused
    # Contains `paste`.
    uutils-coreutils-noprefix
  ];

  runtimeEnv = {
    DOCS_DIR = config.lib.mine.documentsDir;
    OLD_DIRS_COL = hex.toANSI palette.normal.blue;
    NEW_DIRS_COL =
      let
        grayed-out-dirs = {
          "afterglow" = hex.scale 0.85 palette.bright.white;
          "gruvbox" = hex.scale 1.3 palette.bright.black;
          "tokyonight" = "#565f89";
          "vscode" = palette.bright.black;
        };
      in
      hex.toANSI (grayed-out-dirs.${name} or palette.bright.white);
  };

  text = builtins.readFile ./list-files.sh;
}
