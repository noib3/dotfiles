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
        command =
          let
            fzf-alt-c = pkgs.writeShellApplication {
              name = "fzf-alt-c";
              runtimeInputs = with pkgs; [
                config.modules.scripts.frecency
                config.programs.fd.package
                gawk
                gnused
              ];
              runtimeEnv = {
                COL_DIRS = col-dirs;
                COL_GRAYED_OUT_DIRS = col-grayed-out-dirs;
                ROOTS = [
                  "${config.home.homeDirectory}/Desktop"
                  "${config.home.homeDirectory}/Dev"
                  "${config.home.homeDirectory}/Downloads"
                  config.lib.mine.documentsDir
                  config.xdg.configHome
                ];
              };
              text = builtins.readFile ./fzf-alt-c.sh;
            };
          in
          "${lib.getExe fzf-alt-c}";

        options = [
          "--prompt='Cd> '"
          "--preview='ls --color=always ~/{}'"
        ];
      };
    };
  };
}
