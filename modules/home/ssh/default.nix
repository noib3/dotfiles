{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.ssh;
in
{
  options.modules.ssh = {
    enable = mkEnableOption "SSH";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      matchBlocks = {
        auth-canada = {
          hostname = "148.113.207.61";
          user = "nomad";
          identityFile = "${config.home.homeDirectory}/.ssh/skunk";
        };
        remarkable2 = {
          hostname = "10.11.99.1";
          user = "root";
          identityFile = "${config.home.homeDirectory}/.ssh/id_rsa_remarkable2";
        };
        "*" = {
          forwardAgent = false;
          addKeysToAgent = "no";
          compression = false;
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlMaster = "no";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "no";
        };
      };
    };
  };
}
