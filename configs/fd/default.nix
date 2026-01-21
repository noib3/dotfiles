{ lib, pkgs }:

{
  enable = true;

  ignores = [
    "**/.cache"
    "**/.cargo"
    "**/.config"
    "**/.direnv"
    "**/.dropbox"
    "**/.dropbox.cache"
    "**/.git"
    "**/.ipython"
    "**/.local"
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
  ]
  ++ lib.lists.optionals pkgs.stdenv.isDarwin [
    "/.Trash"
    "/Applications"
    "/Library"
    "/Music"
    "/Pictures"
  ];
}
