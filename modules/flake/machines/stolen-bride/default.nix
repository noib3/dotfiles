{
  inputs,
  username,
  ...
}:

let
  hostname = "stolen-bride";
in
{
  machines."stolen-bride".system = "aarch64-darwin";

  flake.darwinConfigurations."stolen-bride" = inputs.nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [
      ./darwin-configuration.nix
      { nixpkgs.overlays = [ inputs.brew-nix.overlays.default ]; }
    ];
    specialArgs = {
      inherit hostname username;
    };
  };
}
