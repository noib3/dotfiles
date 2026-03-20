{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.fonts;

  stackSubmodule =
    let
      fontSubmodule = import ../font-submodule.nix { inherit lib; };
    in
    types.submodule {
      options = {
        enable = mkEnableOption "this font stack";
        monospace = mkOption {
          type = fontSubmodule;
          description = "The monospace font for this stack";
        };
        sansSerif = mkOption {
          type = fontSubmodule;
          description = "The sans-serif font for this stack";
        };
        serif = mkOption {
          type = fontSubmodule;
          description = "The serif font for this stack";
        };
        emoji = mkOption {
          type = fontSubmodule;
          description = "The emoji font for this stack";
        };
      };
    };

  enabledStacks = removeAttrs cfg.stacks [ "current" ] |> filterAttrs (_: stack: stack.enable);
in
{
  imports = [
    ./blex.nix
    ./docsrs.nix
    ./fira.nix
    ./iosevka.nix
  ];

  options.modules.fonts.stacks = mkOption {
    type = types.submodule {
      freeformType = types.attrsOf stackSubmodule;
      options.current = mkOption {
        type = types.attrs;
        readOnly = true;
        description = ''
          The resolved font configuration for the enabled stack.
        '';
      };
    };
    default = { };
  };

  config = {
    assertions = [
      {
        assertion = (enabledStacks |> attrNames |> length) == 1;
        message = "Exactly one font stack must be enabled";
      }
    ];

    modules.fonts.stacks.current =
      enabledStacks
      |> attrValues
      |> head
      # Turn the `sizes` attrset of all the fonts on the enabled stack into
      # a functor which takes a program name and returns the font size for that
      # program (e.g. `font.sizes "ghostty"`).
      |> mapAttrs (
        _category: font:
        font
        // {
          sizes = {
            __functor = _: program: font.sizes.${program} or font.sizes.default;
          };
        }
      );
  };
}
