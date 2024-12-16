{
  hostName,
  ...
}:

{
  imports = [
    ../../modules/darwin/desktop.nix
  ];

  modules.desktop = {
    enable = true;
    inherit hostName;
  };

  system.stateVersion = 5;
}
