{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.fonts;
  fontSubmodule = import ../font-submodule.nix { inherit lib; };

  # A sizes attrset that uses __functor to fall back to `default` for any
  # program that doesn't have an explicit override.
  mkSizesFunctor =
    sizesAttr:
    let
      overrides = removeAttrs sizesAttr [ "default" ];
    in
    {
      inherit (sizesAttr) default;
      __functor = self: program: overrides.${program} or self.default;
    }
    // overrides;

  wrapFont =
    fontDef:
    fontDef
    // {
      sizes = mkSizesFunctor fontDef.sizes;
    };

  stackSubmodule = types.submodule {
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
          The resolved font configuration for the enabled stack, with sizes
          wrapped in a functor for program-specific fallback access.
        '';
      };
    };
    default = { };
    description = ''
      Font stacks, each mapping categories to specific fonts.
      `stacks.current` is reserved for the resolved enabled stack.
    '';
  };

  config =
    let
      stacks =
        assert
          !(removeAttrs cfg.stacks [ "current" ] ? "current")
          || throw ''
            A font stack cannot be named "current" because
            `modules.fonts.stacks.current` is reserved for the enabled stack.
          '';
        removeAttrs cfg.stacks [ "current" ];

      enabledStacks =
        stacks
        |> mapAttrsToList (
          name: stack: {
            inherit name;
            value = stack;
          }
        )
        |> filter (s: s.value.enable);

      enabled = head enabledStacks;
    in
    {
      assertions = [
        {
          assertion = length enabledStacks == 1;
          message = "Exactly one font stack must be enabled";
        }
      ];

      modules.fonts.stacks.current = {
        monospace = wrapFont enabled.value.monospace;
        sansSerif = wrapFont enabled.value.sansSerif;
        serif = wrapFont enabled.value.serif;
        emoji = wrapFont enabled.value.emoji;
      };
    };
}
