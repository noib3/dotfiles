{ inputs, machines }:

{ config, lib, ... }:

{
  options.machines = {
    current = {
      name = lib.mkOption {
        type = lib.types.singleLineStr;
        readOnly = true;
      };
      system = lib.mkOption {
        type = lib.types.singleLineStr;
        readOnly = true;
      };
      cores = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.positive;
        readOnly = true;
        default = machines.${config.machines.current.name}.cores or null;
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
      isHeadless = lib.mkOption {
        type = lib.types.bool;
        readOnly = true;
        default = machines.${config.machines.current.name}.isHeadless or false;
      };
    };
  }
  // (
    machines
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
}
