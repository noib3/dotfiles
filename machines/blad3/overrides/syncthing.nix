{
  declarative = {
    overrideDevices = false;
    devices = {
      archiv3 = {
        name = "archiv3";
        id = "AVKI7R6-5CCWZIJ-TCDXLT2-DWO5RIL-ZE4NGMR-3CBSLNK-VBRJLRU-WOBLVQB";
      };
    };
    overrideFolders = false;
    folders = {
      "sync" = {
        path = "/home/noib3/sync";
        id = "qu7hn-unrno";
        label = "sync";
        devices = [ "archiv3" ];
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
