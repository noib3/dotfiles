{
  hostName,
  userName,
  ...
}:

{
  imports = [
    ../../modules/darwin
  ];

  modules.desktop = {
    enable = true;
    inherit hostName;
  };

  system.primaryUser = userName;
}
