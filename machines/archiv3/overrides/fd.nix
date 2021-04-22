{ default }:

{
  ignores = [
    "/*"
    "!/dotfil3s"
    "/dotfil3s/machines/*"
    "!/dotfil3s/machines/archiv3"
    "!/Media"
    "!/sync"
    "**/.stfolder"
  ] ++ default.ignores;
}
