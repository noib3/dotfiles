{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.gc-git-repos;
  inherit (pkgs.stdenv) isDarwin isLinux;

  gc-git-repos = pkgs.writeShellApplication {
    name = "gc-git-repos";
    runtimeInputs = [
      pkgs.fd
      pkgs.git
    ];
    text = ''
      documentsDir=${lib.escapeShellArg config.lib.mine.documentsDir}

      if [ ! -d "$documentsDir" ]; then
        exit 0
      fi

      fd -u -t d --prune --print0 '^\.git$' "$documentsDir" | while IFS= read -r -d "" gitDir; do
        repoDir="''${gitDir%/.git}"

        if ! git -C "$repoDir" gc --quiet; then
          printf 'Failed to GC %s\n' "$repoDir" >&2
        fi
      done
    '';
  };
in
{
  options.modules.gc-git-repos = {
    enable = mkEnableOption "daily Git repository garbage collection";
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf isDarwin {
      launchd.agents.gc-git-repos = {
        enable = true;
        config = {
          ProgramArguments = [ (lib.getExe gc-git-repos) ];
          StartCalendarInterval = [
            # Runs every day at 4:30 AM.
            {
              Hour = 4;
              Minute = 30;
            }
          ];
        };
      };
    })

    (mkIf isLinux {
      systemd.user.services.gc-git-repos = {
        Unit.Description = "GC Git repositories under the documents directory";
        Service = {
          Type = "oneshot";
          ExecStart = lib.getExe gc-git-repos;
        };
      };

      systemd.user.timers.gc-git-repos = {
        Unit.Description = "GC Git repositories under the documents directory daily";
        Timer = {
          OnCalendar = "daily";
          Persistent = "true";
          Unit = "gc-git-repos.service";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    })
  ]);
}
