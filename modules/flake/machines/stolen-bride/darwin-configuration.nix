{
  username,
  ...
}:

{
  imports = [
    ../../../darwin
  ];

  modules.desktop = {
    enable = true;
  };

  system.primaryUser = username;
}
