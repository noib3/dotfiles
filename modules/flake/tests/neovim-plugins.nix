{
  inputs,
  ...
}:

{
  perSystem =
    { system, ... }:
    {
      # Run with `nix run .#tests.neovim-plugins`.
      legacyPackages.tests.neovim-plugins = inputs.neovim.tests.${system}.plugins;
    };
}
