{ lib }:
let
  admin-passwords = {
    "noib3" = lib.strings.removeSuffix "\n"
      (builtins.readFile ./secrets/admins.noib3.pwd);
  };
in
{
  user = "couchdb";
  group = "couchdb";
  databaseDir = "/home/couchdb/couchdb";
  extraConfig = ''
    [admins]
    noib3 = ${admin-passwords.noib3}
  '';
}
