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

      matchBlocks = {
        remarkable2 = {
          hostname = "10.11.99.1";
          user = "root";
          port = 22;
          identityFile = "${config.home.homeDirectory}/.ssh/id_rsa_remarkable2";
        };
      };
    };
  };
}
