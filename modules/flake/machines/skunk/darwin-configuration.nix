{
  hostname,
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
}
