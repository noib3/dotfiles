{ lib, ... }:

{
  options.modules.terminal = {
    package = lib.mkOption {
      type = lib.types.package;
      description = "The package of the configured terminal";
    };
  };
}
