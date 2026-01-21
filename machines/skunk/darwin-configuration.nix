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

  ids.gids.nixbld = 350;

  nix = {
    linux-builder.enable = true;
    settings.trusted-users = [
      "root"
      userName
    ];
  };

  system.stateVersion = 5;
}
