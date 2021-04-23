{
  declarative = {
    overrideDevices = false;
    # devices = {
    #   blad3 = {
    #     name = "blad3";
    #     id = "YBV66SW-2G2NQ76-SAGDVMF-J2PYJLR-V2AFZIG-XAULZAH-MMTZMUW-ZYKMCA4";
    #   };
    # };
    overrideFolders = false;
    # folders = {
    #   "sync" = {
    #     path = "/home/nix/sync";
    #     id = "qu7hn-unrno";
    #     label = "sync";
    #     devices = [ "blad3" ];
    #     rescanInterval = 10;
    #     type = "receiveonly";
    #     ignorePerms = false;
    #   };
    # };
  };
  user = "noib3";
  dataDir = "/home/noib3";
  configDir = "/home/noib3/.config/syncthing";
  guiAddress = "0.0.0.0:8384";
}
