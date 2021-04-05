{
  shellAliases = {
    reboot = "sudo shutdown -r now";
    shutdown = "sudo shutdown now";
    xclip = "xclip -selection c";
    lf = builtins.toString ../../../../defaults/lf/launcher;
  };

  shellAbbrs = {
    nrs = "sudo nixos-rebuild switch";
  };
}
