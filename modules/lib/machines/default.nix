{
  lib,
  ...
}:

let
  inherit (lib) types;

  machineModule =
    { name, ... }:
    {
      options = {
        name = lib.mkOption {
          type = types.singleLineStr;
          default = name;
          description = "Machine name.";
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
