{ lib }:

with lib;
let
  mouseBindingType = types.submodule {
    options = {
      mouseAction = mkOption {
        type = types.addCheck types.attrs (
          x: x ? buttonId && builtins.isInt x.buttonId
        );
        description = "The mouse action (click, drag, etc.) that triggers this binding";
      };
      targetAction = mkOption {
        type = import ../actions/action-type.nix { inherit lib; };
        description = "The action to perform when the mouse action occurs";
      };
    };
  };
  mkButtonConfig =
    buttonBindings:
    let
      mouseActionKinds = import ../mice/action-kinds.nix;

      clickActions =
        buttonBindings
        |> filter (binding: binding.mouseAction.kind == mouseActionKinds.click)
        |> map (binding: [
          binding.mouseAction.clickSubtype
          binding.targetAction
        ])
        |> concatLists;

      dragActions =
        buttonBindings
        |> filter (binding: binding.mouseAction.kind == mouseActionKinds.drag)
        |> map (binding: [
          binding.mouseAction.direction
          binding.targetAction
        ])
        |> concatLists;

      gestureConfigs =
        (optional (clickActions != [ ]) [
          { Click = { }; }
          clickActions
        ])
        ++ (optional (dragActions != [ ]) [
          { Move = { }; }
          dragActions
        ]);
    in
    gestureConfigs
    |> map (gestureConfig: [
      0
      gestureConfig
    ])
    |> concatLists;

  toBetterMouseFormat =
    bindings:
    groupBy (binding: toString binding.mouseAction.buttonId) bindings
    |> mapAttrsToList (
      buttonIdStr: buttonBindings: [
        (toInt buttonIdStr)
        (mkButtonConfig buttonBindings)
      ]
    )
    |> concatLists;
in
mkOption {
  type = types.submodule (
    { config, ... }:
    {
      options.bindings = mkOption {
        type = types.listOf mouseBindingType;
        description = "Mouse button bindings for this app";
        default = [ ];
      };

      options.lock = mkOption {
        type = types.bool;
        description = ''
          When unlocked, changes to global mouse bindings are synchronized to
          this app, including click-through and pan settings. When locked, this
          app's bindings are independent.
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
  description = "Mouse button bindings and related settings for this app";
}
