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
    inherit hostName userName;
  };

  nix.settings = {
    trusted-users = [
      "root"
      userName
    ];
  };

  system.stateVersion = 5;
}
