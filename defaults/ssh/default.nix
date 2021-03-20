{
  matchBlocks = {
    sync = {
      user = "nix";
      hostname = "46.101.51.224";
      identityFile = "~/.ssh/sync_ecdsa";
      serverAliveInterval = 120;
    };

    pepenerostore = {
      user = "nix";
      hostname = "139.59.168.21";
      identityFile = "~/.ssh/pepenerostore_ecdsa";
      serverAliveInterval = 120;
    };
  };
}
