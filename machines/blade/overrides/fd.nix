{ default }:

{
  ignores = [
    "/*"
    "!/Downloads"
    "!/sync"
  ] ++ default.ignores;
}
