{
  matchBlocks = {
    sync = {
      user = "nix";
      hostname = "46.101.51.224";
      identityFile = "~/.ssh/sync_ecdsa";
      serverAliveInterval = 120;
    };

    pepenerostore = {
      user = "pepe";
      hostname = "138.68.144.16";
      identityFile = "~/.ssh/pepenerostore_ecdsa";
      serverAliveInterval = 120;
    };
  };
}
