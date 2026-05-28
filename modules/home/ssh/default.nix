{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.ssh;
  knownHostsFile = "${config.xdg.stateHome}/ssh/known_hosts";
in
{
  options.modules.ssh = {
    enable = mkEnableOption "SSH";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        remarkable2 = {
          HostName = "10.11.99.1";
          User = "root";
        };
        "*" = {
          AddKeysToAgent = "yes";
          Compression = true;
          HashKnownHosts = true;
          UserKnownHostsFile = knownHostsFile;
        }
        // lib.optionalAttrs pkgs.stdenv.isDarwin {
          UseKeychain = "yes";
        };
      };
    };

    services.ssh-agent.enable = pkgs.stdenv.isLinux;

    home.activation.createSshKnownHostsFile =
      lib.hm.dag.entryAfter [ "writeBoundary" ]
        ''
          run mkdir -p "$(dirname "${knownHostsFile}")"
          run touch "${knownHostsFile}"
          run chmod 644 "${knownHostsFile}"
        '';
  };
}
