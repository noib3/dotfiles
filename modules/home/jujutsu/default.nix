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

        signing = {
          behavior = "own";
          backend = "gpg";
          key = "me@noib3.dev";
        };

        ui = {
          default-command = "log";
          diff-formatter = ":git";
          merge-editor = "vimdiff";
          pager = lib.getExe pkgs.delta;
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
