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
      diff = "delta --paging=never";
      log = "delta --paging=never";
      reflog = "delta --paging=never";
      show = "delta --paging=never";
    };

    interactive = {
      diffFilter = "delta --color-only --paging=never";
    };

    delta = {
      features = "side-by-side line-numbers decorations";
      whitespace-error-style = "22 reverse";

      decorations = {
        commit-decoration-style = "bold yellow box ul";
        file-style = "bold yellow ul";
        file-decoration-style = "none";
      };
    };
  };

  ignores = [
    ".direnv"
    ".envrc"
    "shell.nix"
  ];
}
