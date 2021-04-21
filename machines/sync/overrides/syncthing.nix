{
  declarative = {
    overrideDevices = false;
    devices = {
      blade = {
        name = "blade";
        id = "YBV66SW-2G2NQ76-SAGDVMF-J2PYJLR-V2AFZIG-XAULZAH-MMTZMUW-ZYKMCA4";
      };
    };
    overrideFolders = false;
    folders = {
      "Sync" = {
        path = "/home/nix/Sync";
        id = "qu7hn-unrno";
        label = "Sync";
        devices = [ "blade" ];
        rescanInterval = 10;
        type = "receiveonly";
        ignorePerms = false;
      };
    };
  };
  user = "nix";
  dataDir = "/home/nix";
  configDir = "/home/nix/.config/syncthing";
  guiAddress = "0.0.0.0:8384";
}
