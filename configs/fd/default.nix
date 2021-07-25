{ machine }:

{
  ignored = [
    "/*"
    "!/sync"
    "**/.direnv"
    "**/.git"
    "**/.stfolder"
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
  ] ++ (
    if (machine == "blade" || machine == "mbair") then
      [
        "!/Downloads"
      ]
    else if machine == "archive" then
      [
        "!/dotfiles"
        "/dotfiles/machines/*"
        "!/dotfiles/machines/archive"
      ]
    else [ ]
  );
}
