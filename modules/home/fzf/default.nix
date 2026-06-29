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

      package = pkgs.fzf.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ./patches/super-arrows.patch
          ./patches/kitty-keyboard-protocol.patch
        ];
      });

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
        "--bind='super-left:beginning-of-line,super-right:end-of-line'"
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
              emit_dir_tree() {
                root="$1"
                home="${config.home.homeDirectory}"

                if [ ! -d "$root" ]; then
                  return
                fi

                case "$root" in
                  "$home"/*)
                    prefix="''${root#"$home"/}"
                    ;;
                  *)
                    prefix="$root"
                    ;;
                esac

                (cd "$root" && fd ${fdOpts}) \
                  | sed -u "s|^|"$'\x1b[${col-dirs}m'"$prefix/|"
              }

              {
                emit_dir_tree "${config.home.homeDirectory}/Desktop"
                emit_dir_tree "${config.home.homeDirectory}/Dev"
                emit_dir_tree "${config.home.homeDirectory}/Downloads"
                emit_dir_tree "${config.lib.mine.documentsDir}"
                emit_dir_tree "${config.xdg.configHome}"
              } \
                | sed -u 's|\(.*\)\x1b\[${col-dirs}m/|\1|' \
                | sed -u 's|\x1b\[${col-dirs}m|\x1b\[${col-grayed-out-dirs}m|g' \
                | sed -u 's|\(.*\)\x1b\[${col-grayed-out-dirs}m|\1\x1b\[${col-dirs}m|'
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
