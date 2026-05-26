{
  inputs,
  config,
  lib,
  ...
}:

let
  inherit (lib) types;

  cfg = config.headlessNixosMachine;

  nixosGeneratorsSrc =
    inputs.nixpkgs.legacyPackages.${cfg.system}.nixos-generators.src;

  homeManagerMachinesModule =
    import ../../flake/machines/home-manager-machines-module.nix
      {
        inherit inputs;
        machines = cfg.machines;
      };
in
{
  options = {
    headlessNixosMachine = {
      name = lib.mkOption {
        type = types.singleLineStr;
        description = "Name of the concrete headless NixOS machine.";
      };

      system = lib.mkOption {
        type = types.singleLineStr;
        description = "System architecture of the concrete headless NixOS machine.";
      };

      username = lib.mkOption {
        type = types.singleLineStr;
        description = "Primary user name.";
      };

      colorscheme = lib.mkOption {
        type = types.singleLineStr;
        description = "Home Manager colorscheme to enable for the primary user.";
      };

      machines = lib.mkOption {
        type = types.attrsOf types.raw;
        description = "Machine metadata exposed to the embedded Home Manager config.";
      };

      extraConfig = lib.mkOption {
        type = types.nullOr types.deferredModule;
        default = null;
        description = "Additional NixOS module merged into the generated headless machine.";
      };
    };

    nixosConfigurations = lib.mkOption {
      type = types.attrsOf types.raw;
      readOnly = true;
      description = "Generated NixOS configurations.";
    };
  };

  config.nixosConfigurations.${cfg.name} = inputs.nixpkgs.lib.nixosSystem {
    system = cfg.system;
    modules = [
      ./nixos-configuration.nix
    ]
    ++ lib.optional (cfg.extraConfig != null) cfg.extraConfig;
    specialArgs = {
      hostname = cfg.name;
      inherit
        homeManagerMachinesModule
        inputs
        nixosGeneratorsSrc
        ;
      inherit (cfg)
        colorscheme
        system
        username
        ;
    };
  };
}
