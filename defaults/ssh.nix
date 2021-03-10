{
  matchBlocks = {
    ocean = {
      user = "noibe";
      hostname = "64.227.35.152";
      identityFile = "~/.ssh/ocean_rsa";
    };

    sync = {
      user = "nix";
      hostname = "46.101.51.224";
      identityFile = "~/.ssh/sync_ecdsa";
      serverAliveInterval = 120;
    };
  };
}
