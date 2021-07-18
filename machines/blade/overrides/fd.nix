{ default }:

{
  ignored = [
    "/*"
    "!/Downloads"
    "!/sync"
  ] ++ default.ignored;
}
