{
  userName = "noib3";
  userEmail = "riccardo.mazzarini@pm.me";

  extraConfig = {
    pull = {
      rebase = false;
    };
  };

  ignores = [
    ".envrc"
    "shell.nix"
  ];
}
