{ default }:

{
  ignores = [
    "/*"
    "**/.stfolder"
    "!/Downloads"
    "!/sync"
    "/sync/fitness"
    "/sync/memories"
    "/sync/secrets"
    "/sync/university/*"
    "!/sync/university/magistrale-bocconi/"
  ] ++ default.ignores;
}
