{
  inputs,
  config,
  lib,
  ...
}:

let
  inherit (lib) types;
in
{
  options = {
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

    machines = lib.mkOption {
      type = types.attrsOf types.raw;
      description = "Machine metadata exposed to the embedded Home Manager config.";
    };

    extraConfig = lib.mkOption {
      type = types.nullOr types.deferredModule;
      default = null;
      description = "Additional NixOS module merged into the generated headless machine.";
    };

    nixosConfiguration = lib.mkOption {
      type = types.raw;
      readOnly = true;
      description = "Evaluated NixOS configuration for the concrete headless machine.";
    };
  };

  config.nixosConfiguration = inputs.nixpkgs.lib.nixosSystem {
    inherit (config) system;
    modules = [
      ./nixos-configuration.nix
      ../machines
      {
        machines = config.machines // {
          current = {
            inherit (config) system name;
            isHeadless = true;
          };
        };
      }
    ]
    ++ lib.optional (config.extraConfig != null) config.extraConfig;
    specialArgs = {
      inherit inputs;
      inherit (config) system username;
    };
  };
}
