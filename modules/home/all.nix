{ ... }:

{
  imports = [
    ./ags
    ./dropbox
  ];

  modules = {
    ags.enable = true;
    dropbox.enable = true;
  };
}
