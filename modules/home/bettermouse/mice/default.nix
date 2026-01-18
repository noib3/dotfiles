# Defines the `bettermouse.mice` submodule.

{ lib, mouseActionKinds }:

with lib;
let
  mkMouseOption =
    module:
    mkOption {
      type = types.submoduleWith {
        specialArgs = { inherit mouseActionKinds; };
        modules = [
          ./base-mouse-module.nix
          module
        ];
      };
      default = { };
    };
in
mkOption {
  type = types.submodule {
    options = {
      logitech = mkOption {
        type = types.submodule {
          options = {
            MXMaster3SForMac = mkMouseOption ./logitech/mx-master-3s-for-mac.nix;
          };
        };
        default = { };
      };
    };
  };

  description = "Mouse-specific settings keyed by vendor and product name";

  default = { };
}
