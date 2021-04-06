{ default }:

{
  ignores = [
    "/*"
    "**/.stfolder"
    "!/Downloads"
    "!/Sync"
    "/Sync/fitness/logs/2019"
    "/Sync/fitness/logs/2020"
    "/Sync/memories/2017"
    "/Sync/memories/2018"
    "/Sync/memories/2019"
    "/Sync/memories/2020"
    "/Sync/memories/2021/videos"
    "/Sync/secrets/*"
    "!/Sync/secrets/passwords"
    "!/Sync/secrets/ssh-keys"
    "/Sync/university/*"
    "!/Sync/university/magistrale-bocconi/"
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
  ] ++ default.ignores;
}
