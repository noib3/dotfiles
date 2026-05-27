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
  ];

  config = {
    systems =
      removeAttrs config.machines [ "current" ]
      |> builtins.attrValues
      |> map (m: m.system)
      |> lib.lists.unique;

    flake.homeConfigurations =
      removeAttrs config.machines [ "current" ]
      |> lib.mapAttrs (
        _: machine:
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
      );
  };
}
