{
  inputs,
  config,
  lib,
  ...
}:

let
  inherit (lib) types;
  cfg = config.headlessNixosMachine;
in
{
  options.headlessNixosMachine = {
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

  options.nixosConfiguration = lib.mkOption {
    type = types.raw;
    readOnly = true;
    description = "Evaluated NixOS configuration for the concrete headless machine.";
  };

  config.nixosConfiguration = inputs.nixpkgs.lib.nixosSystem {
    inherit (cfg) system;
    modules = [
      ./nixos-configuration.nix
      ../machines
      {
        machines = cfg.machines // {
          current = {
            inherit (cfg) system name;
            isHeadless = true;
          };
        };
      }
    ]
    ++ lib.optional (cfg.extraConfig != null) cfg.extraConfig;
    specialArgs = {
      inherit
        inputs
        ;
      inherit (cfg)
        colorscheme
        system
        username
        ;
    };
  };
}
