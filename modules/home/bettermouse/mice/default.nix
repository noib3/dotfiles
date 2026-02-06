# Defines the `bettermouse.mice` submodule.

{ lib }:

with lib;
let
  mkMouseOption =
    module:
    mkOption {
      type = types.submoduleWith {
        modules = [
          ./base-mouse-module.nix
          module
        ];
      };
      default = { };
    };
in
mkOption {
  type = types.submodule (
    { config, options, ... }:
    {
      options = {
        logitech = import ./logitech { inherit lib mkMouseOption; };

        asBetterMouseFormat = mkOption {
          type = types.attrs;
          internal = true;
          readOnly = true;
          default = {
            mice =
              config
              |> filterAttrs (name: _: !(options.${name}.internal or false))
              |> mapAttrsToList (
                _vendor: products:
                products
                |> filterAttrs (_: v: v ? enable)
                |> mapAttrsToList (
                  _product: mouseConfig:
                  if mouseConfig.enable then mouseConfig.asBetterMouseFormat else null
                )
                |> filter (x: x != null)
              )
              |> concatLists;
          };
        };
      };
    }
  );

  description = "Mouse-specific settings keyed by vendor and product name";

  default = { };
}
