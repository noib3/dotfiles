{ default }:

{
  ignores = [
    "/*"
    "!/dotfiles"
    "/dotfiles/machines/*"
    "!/dotfiles/machines/archiv3"
    "!/sync"
  ] ++ default.ignores;
}
