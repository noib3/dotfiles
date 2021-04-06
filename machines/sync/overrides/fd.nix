{ default }:

{
  ignores = [
    "/*"
    "!/dotfiles"
    "/dotfiles/machines/*"
    "!/dotfiles/machines/sync"
    "!/Media"
    "!/Sync"
    "**/.stfolder"
  ] ++ default.ignores;
}
