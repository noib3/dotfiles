{
  inputs,
  username,
  ...
}:

let
  hostname = "stolen-bride";
in
{
  machines."stolen-bride" = {
    system = "aarch64-darwin";
    darwinConfiguration = inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [ ./darwin-configuration.nix ];
      specialArgs = {
        inherit hostname username;
      };
    };
  };
}
