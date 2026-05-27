{
  inputs,
  config,
  lib,
  colorscheme,
  fontstack,
  username,
  ...
}:

{
  imports = [
    ../../lib/machines
    ./skunk
    ./stolen-bride
    # Unlike `nixosConfigurations`, `darwinConfigurations` is not a default
    # option in the flake output schema, so we need to define it as an attrset
    # to be able to add keys into it from multiple machines modules.
    {
      options.flake.darwinConfigurations = lib.mkOption {
        type = lib.types.attrsOf lib.types.raw;
        default = { };
      };
    }
  ];

  config = {
    systems =
      removeAttrs config.machines [ "current" ]
      |> builtins.attrValues
      |> map (m: m.system)
      |> lib.lists.unique;

    flake.homeConfigurations =
      removeAttrs config.machines [ "current" ]
      |> lib.mapAttrs' (
        _: machine:
        lib.nameValuePair machine.homeConfigurationName (
          inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = inputs.nixpkgs.legacyPackages.${machine.system};

            modules = [
              ../../home
              ../../lib/machines
              {
                home.username = username;
                machines = config.machines // {
                  current = machine;
                };
                modules.colorschemes.${colorscheme}.enable = true;
                modules.fonts.stacks.${fontstack}.enable = true;
                nixpkgs.overlays = [ inputs.brew-nix.overlays.default ];
              }
            ];

            extraSpecialArgs = {
              inherit inputs;
            };
          }
        )
      );
  };
}
