{
  lib,
  ...
}:

let
  inherit (lib) types;

  machineModule =
    { config, name, ... }:
    {
      options = {
        name = lib.mkOption {
          type = types.singleLineStr;
          default = name;
          description = "Machine name";
        };

        system = lib.mkOption {
          type = types.singleLineStr;
          description = "The system architecture.";
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

        hostName = lib.mkOption {
          type = types.singleLineStr;
          default = config.name;
          description = "Machine's hostname";
        };

        homeConfigurationName = lib.mkOption {
          type = types.singleLineStr;
          default = config.name;
          description = ''
            The key in the flake's 'homeConfigurations' output attrset
            specifying the machine's home-manager configuratin
          '';
        };

        darwinConfigurationName = lib.mkOption {
          type = types.nullOr types.singleLineStr;
          default = null;
          description = ''
            The key in the flake's 'darwinConfigurations' output attrset
            specifying the machine's nix-darwin configuratin
          '';
        };

        nixosConfigurationName = lib.mkOption {
          type = types.nullOr types.singleLineStr;
          default = null;
          description = ''
            The key in the flake's 'nixosConfigurations' output attrset
            specifying the machine's NixOS configuratin
          '';
        };
      };
    };
in
{
  options.machines = lib.mkOption {
    type = types.submodule {
      freeformType = types.attrsOf (types.submodule machineModule);
      options.current = lib.mkOption {
        type = types.submodule machineModule;
      };
    };
    default = { };
  };
}
