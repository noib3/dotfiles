{
  user = "couchdb";
  group = "couchdb";
  databaseDir = "/home/couchdb/couchdb";
  extraConfig = ''
    [admins]
    noib3 = password;

    [chttpd]
    port = 5984
    bind_address = 0.0.0.0

    [httpd]
    bind_address = 0.0.0.0
  '';
}
