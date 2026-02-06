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
in
{
  option = mkOption {
    type = types.listOf mouseBindingType;
    description = "Mouse button bindings for this app";
    default = [ ];
  };

  # Convert a list of mouse bindings to BetterMouse's btn array format.
  toBetterMouseFormat =
    let
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
    in
    bindings:
    groupBy (binding: toString binding.mouseAction.buttonId) bindings
    |> mapAttrsToList (
      buttonIdStr: buttonBindings: [
        (toInt buttonIdStr)
        (mkButtonConfig buttonBindings)
      ]
    )
    |> concatLists;
}
