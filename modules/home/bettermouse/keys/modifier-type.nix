# Defines the type for modifier keys.

{ lib }:

with lib;
types.submodule {
  options.keyBinding = mkOption {
    type = types.int;
    readOnly = true;
  };
  options.nsEventFlag = mkOption {
    type = types.int;
    readOnly = true;
  };
}
