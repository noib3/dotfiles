{
  config,
  pkgs,
}:

let
  inherit (config.lib.mine) hex;
  colors = import ../fzf/colors.nix { inherit config; };

  homeRoots = [
    "${config.home.homeDirectory}/Desktop"
    "${config.home.homeDirectory}/Dev"
    "${config.home.homeDirectory}/Downloads"
    config.lib.mine.documentsDir
    config.xdg.configHome
  ];
in
pkgs.writeShellApplication {
  name = "list-dirs";

  runtimeInputs = with pkgs; [
    config.modules.scripts.frecency
    config.programs.fd.package
    gawk
  ];

  runtimeEnv = {
    DIRS_COL = hex.toANSI colors.directories;
    GRAYED_OUT_DIRS_COL = hex.toANSI colors.grayed-out-directories;
    HOME_ROOTS = homeRoots;
  };

  text = builtins.readFile ./list-dirs.sh;
}
// {
  inherit homeRoots;
}
