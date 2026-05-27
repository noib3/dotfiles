{
  inputs,
  config,
  username,
  ...
}:

let
  hostname = "skunk";
  darwinPartitionMachineName = "${hostname}@darwin";
  linuxPartitionMachineName = "${hostname}@linux";
in
{
  machines.${darwinPartitionMachineName} = {
    system = "x86_64-linux";
  };

  machines.${linuxPartitionMachineName} = {
    system = "x86_64-darwin";
  };

  flake.darwinConfigurations.${darwinPartitionMachineName} =
    inputs.nix-darwin.lib.darwinSystem
      {
        inherit (config.machines.${darwinPartitionMachineName}) system;
        modules = [
          ./darwin-configuration.nix
          { nixpkgs.overlays = [ inputs.brew-nix.overlays.default ]; }
          ../../../lib/machines
          {
            machines = config.machines // {
              current = config.machines.${darwinPartitionMachineName};
            };
          }
        ];
        specialArgs = {
          inherit
            hostname
            inputs
            username
            ;
        };
      };

  flake.nixosConfigurations.${linuxPartitionMachineName} =
    inputs.nixpkgs.lib.nixosSystem
      {
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
            hostname
            inputs
            username
            ;
        };
      };
}
