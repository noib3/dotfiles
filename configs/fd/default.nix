{ lib, pkgs }:

{
  enable = true;

  ignores = [
    "**/.cache"
    "**/.direnv"
    "**/.dropbox.cache"
    "**/.git"
    "**/.stfolder"
    "**/gnupg/*"
    "**/target"
    "*.aux"
    "*.bbl"
    "*.bcf"
    "*.blg"
    "*.dropbox"
    "*.loe"
    "*.log"
    "*.out"
    "*.run.xml"
    "*.synctex(busy)"
    "*.synctex.gz"
    "*.toc"
  ] ++ lib.lists.optionals pkgs.stdenv.isDarwin [ "/Library" ];
}
