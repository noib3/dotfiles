{
  matchBlocks = {
    ocean = {
      user = "noibe";
      hostname = "64.227.35.152";
      identityFile = "~/.ssh/ocean_rsa";
    };

    nix1 = {
      user = "nix";
      hostname = "142.93.34.161";
      identityFile = "~/.ssh/treed-main_ecdsa";
      serverAliveInterval = 120;
    };
  };
}
