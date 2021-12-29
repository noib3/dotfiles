{ machine }:

{
  ignored = [
    "/*"
    "!/Dropbox"
    "!/Downloads"
    "!/.config"
    "/.config/*"
    "**/.direnv"
    "**/.dropbox.cache"
    "**/.git"
    "**/.stfolder"
    "**/gnupg/*"
    "*.dropbox"
    "*.aux"
    "*.bbl"
    "*.bcf"
    "*.blg"
    "*.loe"
    "*.log"
    "*.out"
    "*.run.xml"
    "*.synctex(busy)"
    "*.synctex.gz"
    "*.toc"

    "**/flutter"
    "**/android-sdk"
  ];
}
