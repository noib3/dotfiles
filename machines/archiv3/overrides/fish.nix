{
  shellAliases = {
    reboot = "sudo shutdown -r now";
    shutdown = "sudo shutdown now";
    open = "xdg-open";
  };

  shellAbbrs = {
    nrs = "sudo nixos-rebuild switch";
  };
}
