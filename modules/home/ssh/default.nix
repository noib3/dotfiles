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
      matchBlocks = {
        auth-canada = {
          hostname = "148.113.207.61";
          user = "nomad";
        };
        remarkable2 = {
          hostname = "10.11.99.1";
          user = "root";
        };
        "*" = {
          addKeysToAgent = "yes";
          compression = true;
          hashKnownHosts = true;
          userKnownHostsFile = knownHostsFile;
        };
      };
      extraConfig = ''
        ${lib.optionalString pkgs.stdenv.isDarwin "UseKeychain yes"}
      '';
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
