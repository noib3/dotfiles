{ inputs, colorscheme, userName, ... }:

rec {
  name = "stolen-bride";
  system = "aarch64-darwin";
  darwinConfiguration =
    pkgs:
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      modules = [ ./darwin-configuration.nix ];
      specialArgs = {
        inherit colorscheme userName;
        hostName = name;
      };
    };
}
