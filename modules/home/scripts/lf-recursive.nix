{
  config,
  pkgs,
}:

let
  inherit (config.lib.mine) hex;
  inherit (config.modules.colorscheme) name palette;
  old-dirs-col = hex.toANSI palette.normal.blue;
  grayed-out-dirs = {
    "afterglow" = hex.scale 0.85 palette.bright.white;
    "gruvbox" = hex.scale 1.3 palette.bright.black;
    "tokyonight" = "#565f89";
    "vscode" = palette.bright.black;
  };
  new-dirs-col = hex.toANSI (grayed-out-dirs.${name} or palette.bright.white);
in
pkgs.writeShellApplication {
  name = "lf-recursive";

  runtimeInputs = with pkgs; [
    fd
    gnused
    # Contains `sort`.
    uutils-coreutils-noprefix
  ];

  text = ''
    inner_lf_recursive() {
      ${builtins.readFile ./lf-recursive.sh}
    }

    if [ $# -ne 1 ]; then
      echo "error: expected a directory path as the only argument"
      exit 1
    fi

    if [ ! -d "$1" ]; then
      echo "error: the argument is not a path to a directory"
      exit 1
    fi

    inner_lf_recursive "$1" "${old-dirs-col}" "${new-dirs-col}" "${config.lib.mine.documentsDir}"
  '';
}
