{ pkgs, default }:

{
  shellAliases = {
    reboot = ''osascript -e "tell app \"System Events\" to restart"'';
    shutdown = ''osascript -e "tell app \"System Events\" to shut down"'';
  };

  plugins =
    default.plugins ++ [
      {
        name = "bass";
        src = pkgs.fetchFromGitHub {
          owner = "edc";
          repo = "bass";
          rev = "2fd3d2157d5271ca3575b13daec975ca4c10577a";
          sha256 = "0mb01y1d0g8ilsr5m8a71j6xmqlyhf8w4xjf00wkk8k41cz3ypky";
        };
      }
    ];

  interactiveShellInit =
    default.interactiveShellInit + ''
      bass source ~/.nix-profile/etc/profile.d/nix{,-daemon}.sh 2>/dev/null \
        || true
    '';
}
