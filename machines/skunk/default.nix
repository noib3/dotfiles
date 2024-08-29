let
  hostName = "skunk";
in
{
  linux =
    { inputs, userName, ... }:
    rec {
      name = "skunk@linux";
      system = "x86_64-linux";
      nixosConfiguration =
        pkgs:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system pkgs;
          modules = [
            ./configuration.nix
            ../../modules/block-domains.nix
            inputs.nixos-hardware.nixosModules.apple-t2
          ];
          specialArgs = {
            inherit hostName userName;
          };
        };
    };

  darwin =
    { inputs, colorscheme, ... }:
    rec {
      name = "skunk@darwin";
      system = "x86_64-darwin";
      darwinConfiguration =
        pkgs:
        inputs.nix-darwin.lib.darwinSystem {
          inherit system;
          modules = [ ./darwin-configuration.nix ];
          specialArgs = {
            inherit colorscheme hostName;
          };
        };
    };
}
