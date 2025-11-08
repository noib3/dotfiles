{
  hostName,
  userName,
  ...
}:

{
  imports = [
    ../../modules/darwin
  ];

  modules = {
    brave-policies.enable = true;
    desktop = {
      enable = true;
      inherit hostName userName;
    };
    fish.enable = true;
    yabai.enable = true;
  };

  nix = {
    linux-builder.enable = true;
    settings.trusted-users = [
      "root"
      userName
    ];
  };

  system.stateVersion = 5;
}
