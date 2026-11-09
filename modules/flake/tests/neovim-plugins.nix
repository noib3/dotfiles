{
  inputs,
  ...
}:

{
  perSystem =
    { pkgs, system, ... }:
    {
      # Run with `nix run .#tests.neovim-plugins`. Building the script runs the
      # tests.
      legacyPackages.tests.neovim-plugins = pkgs.writeShellScriptBin "neovim-plugins" ''
        # Force evaluation of ${inputs.neovim.tests.${system}.plugins}.
        echo -e "\033[1;32m✓\033[0m Tests 'neovim-plugins' passed"
      '';
    };
}
