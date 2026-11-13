{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.fzf;
  colors = import ./colors.nix { inherit config; };
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

      defaultCommand = "${lib.getExe config.modules.scripts.list-files} $HOME";

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

      changeDirWidget = {
        command = "${lib.getExe config.modules.scripts.list-dirs} --frecent-first $HOME";

        options = [
          "--prompt='Cd> '"
          "--preview='ls --color=always ~/{}'"
        ];
      };
    };
  };
}
