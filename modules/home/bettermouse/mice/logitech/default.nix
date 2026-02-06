# Defines the `bettermouse.mice.logitech` submodule.

{ lib, mkMouseOption }:

with lib;
mkOption {
  type = types.submodule {
    options = {
      MXMaster3SForMac = mkMouseOption ./mx-master-3s-for-mac.nix;
    };
  };
  default = { };
}
