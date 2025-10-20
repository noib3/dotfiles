{ config, lib, ... }:

let
  cfg = config.modules.terminal;
in
{
  options.modules.terminal = {
    package = lib.mkOption {
      type = lib.types.package;
      description = "The package of the configured terminal";
    };
    launchCommand = lib.mkOption {
      type = lib.types.str;
      description = "The command used to open a new terminal window";
      default = "${lib.getExe cfg.package}";
    };
  };
}
