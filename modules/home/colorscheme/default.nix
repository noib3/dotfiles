{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.colorscheme;

  mkColorschemeOption =
    colorschemeName:
    mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption colorschemeName;
          name = mkOption {
            type = types.str;
            default = colorschemeName;
            description = "The name of the colorscheme";
            readOnly = true;
          };
          palette = mkOption {
            type = types.attrs;
            default = import ./${colorschemeName}.nix;
            description = "The colorscheme's palette";
            readOnly = true;
          };
        };
      };
      default = { };
    };

  colorschemeNames =
    builtins.readDir ./.
    |> builtins.attrNames
    |> builtins.filter (name: name != "default.nix")
    |> map (lib.removeSuffix ".nix");

  colorschemeOptions =
    colorschemeNames
    |> map (name: nameValuePair name (mkColorschemeOption name))
    |> listToAttrs;
in
{
  options.modules.colorscheme = colorschemeOptions // {
    name = mkOption {
      type = types.str;
      description = "The enabled colorscheme's name";
      readOnly = true;
    };

    palette = mkOption {
      type = types.attrs;
      description = "The enabled colorscheme's palette";
      readOnly = true;
    };
  };

  config =
    let
      enabledSchemes =
        removeAttrs cfg ["name" "palette"]
        |> mapAttrsToList (_: value: value)
        |> filter (scheme: scheme.enable);

      enabledScheme = head enabledSchemes;
    in
    {
      assertions = [
        {
          assertion = length enabledSchemes == 1;
          message = "Exactly one colorscheme must be enabled";
        }
      ];

      modules.colorscheme = {
        name = enabledScheme.name;
        palette = enabledScheme.palette;
      };

      home.sessionVariables = {
        COLORSCHEME = cfg.name;
      };
    };
}
