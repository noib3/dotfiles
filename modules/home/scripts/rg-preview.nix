{ pkgs }:

pkgs.writeShellApplication {
  name = "rg-preview";

  runtimeInputs = with pkgs; [
    bat
    file
    gnugrep
    gnupg
  ];

  text = ''
    ${builtins.readFile ./preview-common.sh}
    ${builtins.readFile ./rg-preview.sh}
  '';
}
