{
  inputs,
  username,
  ...
}:

let
  hostname = "skunk";
in
{
  machines."skunk@linux" = {
    system = "x86_64-linux";
    nixosConfiguration = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./nixos-configuration.nix
        inputs.nixos-hardware.nixosModules.apple-t2
      ];
      specialArgs = {
        inherit hostname username;
      };
    };
  };

  machines."skunk@darwin" = {
    system = "x86_64-darwin";
    darwinConfiguration = inputs.nix-darwin.lib.darwinSystem {
      system = "x86_64-darwin";
      modules = [ ./darwin-configuration.nix ];
      specialArgs = {
        inherit hostname username;
      };
    };
  };
}
