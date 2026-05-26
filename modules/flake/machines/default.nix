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

  homeManagerMachinesModule = import ./home-manager-machines-module.nix {
    inherit inputs;
    machines = cfg;
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

            cores = lib.mkOption {
              type = types.nullOr types.ints.positive;
              default = null;
              description = "Number of CPU cores available on the machine.";
            };

            isHeadless = lib.mkOption {
              type = types.bool;
              default = false;
              description = "Whether the machine is expected to run without a graphical session.";
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
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.${machine.system};

          modules = [
            ../../home
            homeManagerMachinesModule
            {
              home.username = username;
              machines.current.name = machineName;
              machines.current.system = machine.system;
              modules.colorschemes.${colorscheme}.enable = true;
              modules.fonts.stacks.${fontstack}.enable = true;
              nixpkgs.overlays = [ inputs.brew-nix.overlays.default ];
            }
          ];

          extraSpecialArgs = { inherit inputs; };
        }
      );
  };
}
