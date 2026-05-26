{
  inputs,
  config,
  username,
  ...
}:

let
  hostname = "stolen-bride";
  machinesModule = import ../home-manager-machines-module.nix {
    inherit inputs;
    machines = config.machines;
  };
in
{
  machines."stolen-bride" = {
    system = "aarch64-darwin";
    cores = 10;
  };

  flake.darwinConfigurations."stolen-bride" = inputs.nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [
      machinesModule
      ./darwin-configuration.nix
      {
        machines.current.name = "stolen-bride";
        machines.current.system = "aarch64-darwin";
      }
      { nixpkgs.overlays = [ inputs.brew-nix.overlays.default ]; }
    ];
    specialArgs = {
      inherit hostname username;
    };
  };
}
