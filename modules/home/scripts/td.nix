{
  config,
  pkgs,
}:

pkgs.writeShellApplication {
  name = "td";

  text = ''
    inner() {
      ${builtins.readFile ./td.sh}
    }
    inner "${config.lib.mine.documentsDir}"
  '';
}
