{ default }:

{
  ignores = [
    "/*"
    "**/.stfolder"
    "!/Downloads"
    "!/Sync"
    "/Sync/fitness"
    "/Sync/memories"
    "/Sync/secrets"
    "/Sync/university/*"
    "!/Sync/university/magistrale-bocconi/"
  ] ++ default.ignores;
}
