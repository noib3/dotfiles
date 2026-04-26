{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.delete-ds-store;

  delete-ds-store = pkgs.writeShellApplication {
    name = "delete-ds-store";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.fd
    ];
    text = ''
      homeDir=${lib.escapeShellArg config.home.homeDirectory}
      fd -u -t f '^\.DS_Store$' "$homeDir" -x rm -- {}
    '';
  };
in
{
  options.modules.delete-ds-store = {
    enable = mkEnableOption "daily .DS_Store cleanup";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = ".DS_Store files are only created on macOS";
      }
    ];

    launchd.agents.delete-ds-store = {
      enable = true;
      config = {
        ProgramArguments = [ (lib.getExe delete-ds-store) ];
        StartCalendarInterval = [
          # Runs every day at 4:00 AM.
          {
            Hour = 4;
            Minute = 0;
          }
        ];
      };
    };
  };
}
