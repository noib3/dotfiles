{
  config,
  pkgs,
  ...
}:

{
  config = {
    nixpkgs.overlays = [
      (final: prev: {
        scripts = {
          fuzzy-ripgrep = import ./fuzzy-ripgrep.nix { inherit pkgs; };
          lf-recursive = import ./lf-recursive.nix { inherit config pkgs; };
          preview = import ./preview.nix { inherit pkgs; };
          rg-pattern = import ./rg-pattern.nix { inherit pkgs; };
          rg-preview = import ./rg-preview.nix { inherit pkgs; };
        };
      })
    ];
  };
}
