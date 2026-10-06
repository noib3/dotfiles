{ config, lib, ... }:

with lib;
let
  cfg = config.modules.snowstorm-work;
  sshHostname = "github-snowstorm";
  workEmail = "riccardo@snowstorm.net";
in
{
  options.modules.snowstorm-work = {
    enable = mkEnableOption "Snowstorm-related Git/Jujutsu/SSH configs";
  };

  config = mkIf cfg.enable {
    programs.git = {
      includes = [
        {
          condition = "gitdir:**/snowstorm/**";
          contents = {
            user = {
              email = workEmail;
              signingkey = workEmail;
            };
          };
        }
      ];

      settings.url."ssh://git@${sshHostname}/project-snowstorm/".insteadOf = [
        "git@github.com:project-snowstorm/"
        "ssh://git@github.com/project-snowstorm/"
      ];
    };

    programs.jujutsu.settings."--scope" = [
      {
        "--when".repositories = [ "${config.home.homeDirectory}/Dev/snowstorm" ];
        user.email = workEmail;
        signing.key = workEmail;
      }
    ];

    programs.ssh.settings.${sshHostname} = {
      HostName = "github.com";
      IdentityFile = "~/.ssh/snowstorm.pk";
      IdentitiesOnly = true;
    };
  };
}
