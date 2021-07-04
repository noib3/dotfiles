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

    pager = {
      # diff = "delta";
      log = "delta";
      reflog = "delta";
      show = "delta";
    };

    interactive = {
      diffFilter = "delta --color-only";
    };

    delta = {
      features = "line-numbers decorations";
      syntax-theme = "TwoDark";
      decorations = {
        file-style = "omit";
        commit-decoration-style = "bold yellow box ul";
      };
    };
  };

  ignores = [
    ".direnv"
    ".envrc"
    "shell.nix"
  ];
}
