{ config, lib, ... }:

with lib;
let
  cfg = config.modules.snowstorm-work;
  sshHostname = "github-snowstorm";
in
{
  options.modules.snowstorm-work = {
    enable = mkEnableOption "Snowstorm-related Git/SSH configs";
  };

  config = mkIf cfg.enable {
    programs.git = {
      includes = [
        {
          condition = "gitdir:**/snowstorm/**";
          contents.user = {
            email = "riccardo@snowstorm.net";
            signingkey = "F37C362AF715BC43";
          };
        }
      ];

      settings.url."git@${sshHostname}:project-snowstorm/".insteadOf = [
        "ssh://git@github.com/project-snowstorm/"
        "git@github.com:project-snowstorm/"
      ];
    };

    programs.ssh.matchBlocks.${sshHostname} = {
      hostname = "github.com";
      identityFile = "~/.ssh/snowstorm.pk";
      identitiesOnly = true;
    };
  };
}
