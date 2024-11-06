{ lib, pkgs }:

{
  enable = true;

  ignores =
    [
      "**/.cache"
      "**/.cargo"
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
      "/Library"
      "/Music"
      "/Pictures"
    ];
}
