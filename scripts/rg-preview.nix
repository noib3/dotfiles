{ pkgs }:

pkgs.writeShellApplication {
  name = "rg-preview";

  runtimeInputs = with pkgs; [
    bat
    file
  ];

  text = ''
    ${builtins.readFile ./rg-preview.sh}
  '';
}
