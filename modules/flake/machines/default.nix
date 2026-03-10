{
  inputs,
  config,
  lib,
  colorscheme,
  fonts,
  username,
  ...
}:

let
  inherit (lib) types;

  cfg = config.machines;

  machineNames = builtins.attrNames cfg;

  mkPkgs =
    system:
    import inputs.nixpkgs {
      inherit system;
      overlays = [
        inputs.brew-nix.overlays.default
        inputs.nur.overlays.default
      ];
    };

  # A home-manager module that defines `config.machine` and
  # `config.machines.<name>.isCurrent`.
  homeManagerModule =
    { lib, ... }:
    {
      options.machine = {
        name = lib.mkOption { type = lib.types.str; };
        hasNixosConfiguration = lib.mkOption {
          type = lib.types.bool;
        };
        hasDarwinConfiguration = lib.mkOption {
          type = lib.types.bool;
        };
      };

      options.machines = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = {
            isCurrent = lib.mkOption { type = lib.types.bool; };
          };
        }) machineNames
      );
    };

  # A home-manager module that sets `config.machine` and
  # `config.machines` for a given target machine.
  mkHomeManagerModule =
    targetName: targetMachine:
    { ... }:
    {
      config.machine = {
        name = targetName;
        hasNixosConfiguration = targetMachine.nixosConfiguration != null;
        hasDarwinConfiguration = targetMachine.darwinConfiguration != null;
      };
      config.machines = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = {
            isCurrent = name == targetName;
          };
        }) machineNames
      );
    };

  mkHomeConfiguration =
    name: machine:
    inputs.home-manager.lib.homeManagerConfiguration rec {
      pkgs = mkPkgs machine.system;

      modules = [
        homeManagerModule
        (mkHomeManagerModule name machine)
        ../../../fonts/module.nix
        ../../home
        {
          fonts = fonts pkgs;
          home.username = username;
          modules.colorscheme.${colorscheme}.enable = true;
        }
      ]
      ++ machine.homeManagerModules;

      extraSpecialArgs = { inherit inputs; };
    };
in
{
  imports = [
    ./skunk
    ./stolen-bride
  ];

  options = {
    machines = lib.mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            system = lib.mkOption {
              type = types.str;
              description = "The system architecture.";
            };

            nixosConfiguration = lib.mkOption {
              type = types.nullOr types.raw;
              default = null;
              description = "The NixOS system configuration.";
            };

            darwinConfiguration = lib.mkOption {
              type = types.nullOr types.raw;
              default = null;
              description = "The nix-darwin system configuration.";
            };

            homeManagerModules = lib.mkOption {
              type = types.listOf types.raw;
              default = [ ];
              description = ''
                Extra home-manager modules for this machine.
              '';
            };
          };
        }
      );
      default = { };
      description = "Machine definitions.";
    };
  };

  config = {
    systems = cfg |> builtins.attrValues |> map (m: m.system) |> lib.lists.unique;

    flake = {
      nixosConfigurations = lib.filterAttrs (_: v: v != null) (
        lib.mapAttrs (_: m: m.nixosConfiguration) cfg
      );

      darwinConfigurations = lib.filterAttrs (_: v: v != null) (
        lib.mapAttrs (_: m: m.darwinConfiguration) cfg
      );

      homeConfigurations = lib.mapAttrs mkHomeConfiguration cfg;
    };
  };
}
