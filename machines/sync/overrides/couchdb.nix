{
  user = "couchdb";
  group = "couchdb";
  databaseDir = "/home/couchdb/couchdb";
  extraConfig = ''
    [admins]
    noib3 = password;
  '';
}
