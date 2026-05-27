{
  inputs,
  config,
  username,
  ...
}:

let
  hostname = "stolen-bride";
in
{
  machines.${hostname} = {
    system = "aarch64-darwin";
    cores = 10;
  };

  flake.darwinConfigurations.${hostname} = inputs.nix-darwin.lib.darwinSystem {
    inherit (config.machines.${hostname}) system;
    modules = [
      ./darwin-configuration.nix
      { nixpkgs.overlays = [ inputs.brew-nix.overlays.default ]; }
      ../../../lib/machines
      {
        machines = config.machines // {
          current = config.machines.${hostname};
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
