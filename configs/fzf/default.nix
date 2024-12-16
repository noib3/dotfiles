{
  config,
  pkgs,
  colorscheme,
  palette,
}:

let
  inherit (config.lib.mine) hex;
  colors = import ./colors.nix { inherit config colorscheme palette; };
  col-dirs = hex.toANSI colors.directories;
  col-grayed-out-dirs = hex.toANSI colors.grayed-out-directories;
  lf-recursive = "${pkgs.scripts.lf-recursive}/bin/${pkgs.scripts.lf-recursive.name}";
in
{
  enable = true;

  defaultCommand = "${lf-recursive} $HOME";

  defaultOptions = [
    "--reverse"
    "--no-bold"
    "--info=inline"
    "--height=8"
    "--hscroll-off=50"
    "--ansi"
    "--preview-window=sharp"
    "--preview-window=border-left"
    "--color='hl:-1:underline'"
    "--color='fg+:-1:regular:italic'"
    "--color='hl+:-1:underline:italic'"
    "--color='prompt:4:regular'"
    "--color='pointer:1'"
    "--color='bg+:${colors.current-line.bg}'"
    "--color='border:${colors.border}'"
  ];

  changeDirWidgetCommand = ''
    fd --strip-cwd-prefix --base-directory=$HOME --hidden --type=d --color=always \
      | sed 's|\(.*\)\x1b\[${col-dirs}m/|\1|' \
      | sed 's|\x1b\[${col-dirs}m|\x1b\[${col-grayed-out-dirs}m|g' \
      | sed 's|\(.*\)\x1b\[${col-grayed-out-dirs}m|\1\x1b\[${col-dirs}m|'
  '';

  changeDirWidgetOptions = [
    "--prompt='Cd> '"
    "--preview='ls --color=always ~/{}'"
  ];

  enableFishIntegration = true;
}
