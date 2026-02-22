{
  inputs,
  fonts,
  colorscheme,
  userName,
}@opts:

let
  machineSources = [
    (import ./skunk).linux
    (import ./skunk).darwin
    (import ./stolen-bride)
  ];

  inherit (inputs.nixpkgs) lib;

  mkPkgs =
    system:
    import inputs.nixpkgs {
      inherit system;
      overlays = [
        inputs.brew-nix.overlays.default
        inputs.nur.overlays.default
      ];
    };

  machines = map (
    m:
    let
      machine = m opts;
      pkgs = mkPkgs machine.system;
    in
    {
      name = machine.name;
      nixosConfiguration = machine.nixosConfiguration pkgs;
      darwinConfiguration = machine.darwinConfiguration pkgs;
      homeConfiguration = mkHomeConfiguration machine;
    }
  ) machineSources;

  # A home-manager module that defines `config.machine(s)`.
  homeManagerModule =
    { lib, ... }:
    {
      options.machine = {
        name = lib.mkOption { type = lib.types.str; };
        hasNixosConfiguration = lib.mkOption { type = lib.types.bool; };
        hasDarwinConfiguration = lib.mkOption { type = lib.types.bool; };
      };

      options.machines = builtins.listToAttrs (
        map (machine: {
          name = machine.name;
          value = {
            isCurrent = lib.mkOption { type = lib.types.bool; };
          };
        }) machines
      );
    };

  mkHomeManagerModule =
    targetMachine:
    { ... }:
    {
      config.machine = {
        name = targetMachine.name;
        hasNixosConfiguration = targetMachine ? nixosConfiguration;
        hasDarwinConfiguration = targetMachine ? darwinConfiguration;
      };
      config.machines = builtins.listToAttrs (
        map (machine: {
          name = machine.name;
          value = {
            isCurrent = machine.name == targetMachine.name;
          };
        }) machines
      );
    };

  mkHomeConfiguration =
    machine:
    inputs.home-manager.lib.homeManagerConfiguration rec {
      pkgs = mkPkgs machine.system;

      modules = [
        homeManagerModule
        (mkHomeManagerModule machine)
        ../fonts/module.nix
        ../modules/home
        ../modules/services/bluetooth-autoconnect.nix
        {
          fonts = fonts pkgs;
          home.username = userName;
          modules.colorscheme.${colorscheme}.enable = true;
        }
      ];

      extraSpecialArgs = { inherit inputs; };
    };
in
{
  forEach =
    forMachine:
    (lib.lists.foldl' lib.attrsets.recursiveUpdate { } (map forMachine machines));
}
