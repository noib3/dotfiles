{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.direnv;

  direnvLayoutDir = pkgs.writeShellApplication {
    name = "direnv-layout-dir";
    runtimeEnv = {
      DOCUMENTS = config.lib.mine.documentsDir;
      XDG_STATE_HOME = config.xdg.stateHome;
    };
    text = ''
      ${builtins.readFile ../scripts/project-hash-utils.sh}
      ${builtins.readFile ./direnv-layout-dir.sh}
    '';
  };
in
{
  options.modules.direnv = {
    enable = mkEnableOption "Direnv";
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;

      config = {
        global = {
          disable_stdin = true;
          warn_timeout = "5m";
        };
      };

      # Override the direnv_layout_dir() hook, which direnv calls during .envrc
      # evaluation whenever layout/use helpers need their per-project cache
      # directory. We place those artifacts outside of the project's repo
      # because Proton Drive errors when it finds symlinks to files not under
      # the drive folder.
      stdlib = ''
        direnv_layout_dir() {
          ${lib.getExe direnvLayoutDir}
        }
      '';

      nix-direnv.enable = true;
    };
  };
}
