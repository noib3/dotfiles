{ colorscheme }:

let
  delta-syntax-theme = (
    if colorscheme == "gruvbox" then "gruvbox-dark"
    else "TwoDark"
  );
in
{
  userName = "Riccardo Mazzarini";

  userEmail = "me@noib3.dev";

  signing = {
    key = "me@noib3.dev";
    signByDefault = true;
  };

  extraConfig = {
    init = {
      defaultBranch = "main";
    };

    pull = {
      rebase = false;
    };

    pager = {
      diff = "delta";
      log = "delta";
      reflog = "delta";
      show = "delta";
    };

    interactive = {
      diffFilter = "delta --color-only";
    };

    delta = {
      features = "line-numbers decorations";
      syntax-theme = delta-syntax-theme;
      decorations = {
        file-style = "omit";
        commit-decoration-style = "bold yellow box ul";
      };
    };

    merge = {
      tool = "nvimdiff";
    };
  };

  ignores = [
    ".direnv"
    ".envrc"
  ];
}
