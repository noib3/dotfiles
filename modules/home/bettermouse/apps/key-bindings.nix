{ lib }:

with lib;
let
  keyBindingType = types.submodule {
    options = {
      key = mkOption {
        type = import ../keys/key-type.nix { inherit lib; };
        description = "The key (with optional modifiers) that triggers this binding";
      };
      action = mkOption {
        type = import ../actions/action-type.nix { inherit lib; };
        description = "The action to perform when the key is pressed";
      };
    };
  };

  toBetterMouseFormat =
    bindings:
    groupBy (binding: toString binding.key.code) bindings
    |> mapAttrsToList (
      codeStr: codeBindings: [
        (toInt codeStr)
        (
          codeBindings
          |> map (binding: [
            binding.key.modifiers
            binding.action
          ])
          |> concatLists
        )
      ]
    )
    |> concatLists;
in
mkOption {
  type = types.submodule (
    { config, ... }:
    {
      options.bindings = mkOption {
        type = types.listOf keyBindingType;
        description = "Key bindings for this app";
        default = [ ];
      };

      options.lock = mkOption {
        type = types.bool;
        description = ''
          When unlocked, changes to global key bindings are synchronized to
          this app. When locked, this app's key bindings are independent.
        '';
        default = false;
      };

      options.asBetterMouseFormat = mkOption {
        type = types.listOf types.anything;
        internal = true;
        readOnly = true;
        default = toBetterMouseFormat config.bindings;
      };
    }
  );
  default = { };
  description = "Key bindings and related settings for this app";
}
