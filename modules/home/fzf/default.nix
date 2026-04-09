{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.fzf;
  inherit (config.lib.mine) hex;
  colors = import ./colors.nix { inherit config; };
  col-dirs = hex.toANSI colors.directories;
  col-grayed-out-dirs = hex.toANSI colors.grayed-out-directories;
in
{
  options.modules.fzf = {
    enable = mkEnableOption "fzf";
  };

  config = mkIf cfg.enable {
    programs.fzf = {
      enable = true;

      defaultCommand = "${lib.getExe config.modules.scripts.lf-recursive} $HOME";

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

      changeDirWidgetCommand =
        let
          fdOpts = "--strip-cwd-prefix --hidden --type=d --color=always";
          fzf-alt-c = pkgs.writeShellApplication {
            name = "fzf-alt-c";
            runtimeInputs = with pkgs; [
              config.programs.fd.package
              gnused
            ];
            text = ''
              docs_dir="${config.lib.mine.documentsDir}"
              docs_name="$(basename "$docs_dir")"
              {
                (cd "${config.home.homeDirectory}" && fd ${fdOpts})

                # If the documents directory is a symlink, scan it explicitly since
                # fd doesn't follow symlinks.
                if [ -L "$docs_dir" ]; then
                  (cd "$docs_dir" && fd ${fdOpts}) \
                    | sed "s|^|"$'\x1b[${col-dirs}m'"$docs_name/|"
                fi
              } \
                | sed 's|\(.*\)\x1b\[${col-dirs}m/|\1|' \
                | sed 's|\x1b\[${col-dirs}m|\x1b\[${col-grayed-out-dirs}m|g' \
                | sed 's|\(.*\)\x1b\[${col-grayed-out-dirs}m|\1\x1b\[${col-dirs}m|'
            '';
          };
        in
        "${lib.getExe fzf-alt-c}";

      changeDirWidgetOptions = [
        "--prompt='Cd> '"
        "--preview='ls --color=always ~/{}'"
      ];
    };
  };
}
