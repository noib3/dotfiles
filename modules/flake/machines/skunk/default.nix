{
  inputs,
  config,
  username,
  ...
}:

let
  hostName = "skunk";
  macosPartitionMachineName = "${hostName}@macos";
  linuxPartitionMachineName = "${hostName}@linux";
in
{
  machines.${macosPartitionMachineName} = {
    inherit hostName;
    system = "x86_64-darwin";
    darwinConfigurationName = hostName;
  };

  machines.${linuxPartitionMachineName} = {
    inherit hostName;
    system = "x86_64-linux";
    nixosConfigurationName = hostName;
  };

  flake.darwinConfigurations.${hostName} = inputs.nix-darwin.lib.darwinSystem {
    inherit (config.machines.${macosPartitionMachineName}) system;
    modules = [
      ./darwin-configuration.nix
      { nixpkgs.overlays = [ inputs.brew-nix.overlays.default ]; }
      ../../../lib/machines
      {
        machines = config.machines // {
          current = config.machines.${macosPartitionMachineName};
        };
      }
    ];
    specialArgs = {
      inherit
        inputs
        username
        ;
    };
  };

  flake.nixosConfigurations.${hostName} = inputs.nixpkgs.lib.nixosSystem {
    inherit (config.machines.${linuxPartitionMachineName}) system;
    modules = [
      ./nixos-configuration.nix
      inputs.nixos-hardware.nixosModules.apple-t2
      ../../../lib/machines
      {
        machines = config.machines // {
          current = config.machines.${linuxPartitionMachineName};
        };
      }
    ];
    specialArgs = {
      inherit
        inputs
        username
        ;
    };
  };
}
