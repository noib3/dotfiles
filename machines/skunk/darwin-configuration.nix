{
  hostName,
  userName,
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

  nix.settings = {
    trusted-users = [
      "root"
      userName
    ];
  };

  system.stateVersion = 5;
}
