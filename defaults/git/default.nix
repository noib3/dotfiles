{
  userName = "noib3";
  userEmail = "riccardo.mazzarini@pm.me";

  signing = {
    key = "riccardo.mazzarini@pm.me";
    signByDefault = true;
  };

  extraConfig = {
    pull = {
      rebase = false;
    };
  };

  ignores = [
    ".direnv"
    ".envrc"
    "shell.nix"
  ];
}
