{ pkgs }:

{
  configDir = ./.;

  enable = pkgs.stdenv.isLinux;

  extraPackages = with pkgs; [ cowsay ];

  # package = pkgs.hiPrio (
  #   pkgs.writeShellApplication {
  #     name = "ags";
  #     runtimeInputs = [ pkgs.bun ];
  #     text = "${pkgs.ags}";
  #   }
  # );
}
