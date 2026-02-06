{ lib, ... }:

let
  inherit (lib) mkOption types;
  mouseButtonType = import ./button-type.nix { inherit lib; };
in
{
  options = {
    enable = mkOption {
      type = types.bool;
      description = "Whether to emit this mouse's config";
      default = false;
    };

    buttons = mkOption {
      type = types.attrsOf mouseButtonType;
      description = "Mouse button definitions for bindings";
      readOnly = true;
    };

    asBetterMouseFormat = mkOption {
      type = types.attrs;
      description = "Mouse settings in BetterMouse's expected format";
      readOnly = true;
    };
  };
}
