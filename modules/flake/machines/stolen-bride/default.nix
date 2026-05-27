{
  inputs,
  config,
  username,
  ...
}:

let
  hostName = "stolen-bride";
in
{
  machines.${hostName} = {
    system = "aarch64-darwin";
    cores = 10;
    darwinConfigurationName = hostName;
  };

  flake.darwinConfigurations.${hostName} = inputs.nix-darwin.lib.darwinSystem {
    inherit (config.machines.${hostName}) system;
    modules = [
      ./darwin-configuration.nix
      { nixpkgs.overlays = [ inputs.brew-nix.overlays.default ]; }
      ../../../lib/machines
      {
        machines = config.machines // {
          current = config.machines.${hostName};
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
