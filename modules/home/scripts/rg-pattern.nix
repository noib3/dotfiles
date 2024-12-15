{ pkgs }:

pkgs.writeShellApplication {
  name = "rg-pattern";

  runtimeInputs = with pkgs; [
    gnused
    ripgrep
  ];

  text = ''
    ${builtins.readFile ./rg-pattern.sh}
  '';
}
