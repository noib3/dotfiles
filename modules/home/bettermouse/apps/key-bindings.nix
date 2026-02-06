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
in
{
  option = mkOption {
    type = types.listOf keyBindingType;
    description = "Key bindings for this app";
    default = [ ];
  };

  # Convert a list of key bindings to BetterMouse's key array format.
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
}
