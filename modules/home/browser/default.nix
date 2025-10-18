{ lib, ... }:

{
  options.modules.browser = {
    package = lib.mkOption {
      type = lib.types.package;
      description = "The package of the configured browser";
    };
  };
}
