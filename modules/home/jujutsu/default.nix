{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.modules.jujutsu;
  inherit (pkgs.stdenv.hostPlatform) system;
  delta-syntax-theme = (
    if config.modules.colorschemes.name == "gruvbox" then
      "gruvbox-dark"
    else
      "TwoDark"
  );
in
{
  options.modules.jujutsu = {
    enable = lib.mkEnableOption "Jujutsu";
  };

  config = lib.mkIf cfg.enable {
    programs.jujutsu = {
      enable = true;

      package = inputs.jujutsu.packages.${system}.default.overrideAttrs {
        doCheck = false;
      };

      settings = {
        user = {
          name = "Riccardo Mazzarini";
          email = "me@noib3.dev";
        };

        # Commits are signed when they're pushed, not on every snapshot, which
        # would add a GPG round trip to each jj command run after a file
        # changed.
        signing = {
          behavior = "drop";
          backend = "gpg";
          key = "me@noib3.dev";
        };

        git = {
          executable-path = lib.getExe pkgs.git;
        };

        revsets.git-sign-on-push = "~signed() & mine()";

        ui = {
          default-command = "log";
          diff-formatter = ":git";
          merge-editor = "vimdiff";
          pager = [
            (lib.getExe pkgs.delta)
            "--line-numbers"
            "--file-style=omit"
            "--syntax-theme=${delta-syntax-theme}"
          ];
        };

        merge-tools = {
          delta.diff-expected-exit-codes = [
            0
            1
          ];
          vimdiff.program = lib.getExe config.neovim.package;
        };
      };
    };
  };
}
