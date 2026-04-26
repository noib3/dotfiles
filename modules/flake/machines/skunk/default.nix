{
  inputs,
  username,
  ...
}:

let
  hostname = "skunk";
in
{
  machines."skunk@linux".system = "x86_64-linux";
  machines."skunk@darwin".system = "x86_64-darwin";

  flake.nixosConfigurations."skunk@linux" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./nixos-configuration.nix
      inputs.nixos-hardware.nixosModules.apple-t2
    ];
    specialArgs = {
      inherit hostname username;
    };
  };

  flake.darwinConfigurations."skunk@darwin" = inputs.nix-darwin.lib.darwinSystem {
    system = "x86_64-darwin";
    modules = [
      ./darwin-configuration.nix
      { nixpkgs.overlays = [ inputs.brew-nix.overlays.default ]; }
    ];
    specialArgs = {
      inherit hostname username;
    };
  };
}
