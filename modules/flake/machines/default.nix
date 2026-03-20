{
  inputs,
  config,
  lib,
  colorscheme,
  fontstack,
  username,
  ...
}:

let
  inherit (lib) types;

  cfg = config.machines;

  # A home-manager module that defines `config.machines`.
  homeManagerMachinesModule =
    { config, lib, ... }:
    {
      options.machines = {
        current = {
          name = lib.mkOption {
            type = lib.types.singleLineStr;
            readOnly = true;
          };
          hasNixosConfiguration = lib.mkOption {
            type = lib.types.bool;
            readOnly = true;
            default = inputs.self.nixosConfigurations ? ${config.machines.current.name};
          };
          hasDarwinConfiguration = lib.mkOption {
            type = lib.types.bool;
            readOnly = true;
            default = inputs.self.darwinConfigurations ? ${config.machines.current.name};
          };
        };
      }
      // (
        cfg
        |> lib.mapAttrs (
          machineName: _: {
            isCurrent = lib.mkOption {
              type = lib.types.bool;
              readOnly = true;
              default = machineName == config.machines.current.name;
            };
          }
        )
      );
    };
in
{
  imports = [
    ./skunk
    ./stolen-bride
  ];

  options = {
    flake.darwinConfigurations = lib.mkOption {
      type = types.attrsOf types.raw;
      default = { };
    };

    machines = lib.mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            system = lib.mkOption {
              type = types.singleLineStr;
              description = "The system architecture";
            };
          };
        }
      );
      default = { };
    };
  };

  config = {
    systems =
      assert
        !(cfg ? "current")
        || throw ''
          A machine cannot be named "current" because `machines.current` is
          reserved for the current machine's metadata.
        '';
      cfg |> builtins.attrValues |> map (m: m.system) |> lib.lists.unique;

    flake.homeConfigurations =
      cfg
      |> lib.mapAttrs (
        machineName: machine:
        inputs.home-manager.lib.homeManagerConfiguration rec {
          pkgs = import inputs.nixpkgs {
            inherit (machine) system;
            overlays = [
              inputs.brew-nix.overlays.default
            ];
          };

          modules = [
            homeManagerMachinesModule
            ../../home
            {
              home.username = username;
              machines.current.name = machineName;
              modules.colorscheme.${colorscheme}.enable = true;
              modules.fonts.stacks.${fontstack}.enable = true;
            }
          ];

          extraSpecialArgs = { inherit inputs; };
        }
      );
  };
}
