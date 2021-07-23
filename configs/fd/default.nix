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
    else if machine == "archiv3" then
      [
        "!/dotfiles"
        "/dotfiles/machines/*"
        "!/dotfiles/machines/archiv3"
      ]
    else [ ]
  );
}
