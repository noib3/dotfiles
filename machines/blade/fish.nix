{
  shellAliases = {
    reboot = "sudo shutdown -r now";
    shutdown = "sudo shutdown now";
    xclip = "xclip -selection c";
  };

  shellAbbrs = {
    nrs = "sudo nixos-rebuild switch";
  };
}
