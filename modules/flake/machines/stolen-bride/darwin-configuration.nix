{
  hostname,
  username,
  ...
}:

{
  imports = [
    ../../../darwin
  ];

  modules.desktop = {
    enable = true;
    inherit hostname;
  };

  system.primaryUser = username;
}
