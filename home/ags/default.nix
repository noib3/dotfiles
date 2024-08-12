{ pkgs }:

{
  configDir = ./.;

  extraPackages = with pkgs; [ cowsay ];
}
