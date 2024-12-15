{ pkgs }:

pkgs.writeShellApplication rec {
  name = "website-blocker";

  runtimeInputs = with pkgs; [
    # Contains `id`.
    coreutils
    iptables
    jc
    jq
  ];

  text = ''
    ${builtins.readFile ./website-blocker.sh}
  '';
}
