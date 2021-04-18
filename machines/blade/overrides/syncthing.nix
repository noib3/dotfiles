{
  declarative = {
    overrideDevices = false;
    devices = {
      sync = {
        name = "Sync";
        id = "AVKI7R6-5CCWZIJ-TCDXLT2-DWO5RIL-ZE4NGMR-3CBSLNK-VBRJLRU-WOBLVQB";
      };
    };
    overrideFolders = false;
    folders = {
      "Sync" = {
        path = "/home/noib3/Sync";
        id = "qu7hn-unrno";
        label = "Sync";
        devices = [ "sync" ];
        rescanInterval = 10;
        type = "sendonly";
        ignorePerms = false;
      };
    };
  };
  user = "noib3";
  dataDir = "/home/noib3";
  configDir = "/home/noib3/.config/syncthing";
}
