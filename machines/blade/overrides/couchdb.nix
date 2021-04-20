{
  user = "couchdb";
  group = "couchdb";
  databaseDir = "/home/couchdb/couchdb";
  extraConfig = ''
    [admins]
    admin = password;
  '';
}
