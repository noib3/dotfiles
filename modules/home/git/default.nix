{ config, lib, ... }:

with lib;
let
  cfg = config.modules.git;
  delta-syntax-theme = (
    if config.modules.colorschemes.name == "gruvbox" then
      "gruvbox-dark"
    else
      "TwoDark"
  );
in
{
  options.modules.git = {
    enable = mkEnableOption "Git";
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;

      settings = {
        init.defaultBranch = "main";

        pull.rebase = false;

        push.followTags = true;

        # Pack loose objects once there are more than 100 (default is 6700).
        # Keeps the number of small files in .git/objects low, which helps with
        # Proton Drive sync performance.
        gc.auto = 100;

        pager = {
          diff = "delta";
          log = "delta";
          reflog = "delta";
          show = "delta";
        };

        interactive.diffFilter = "delta --color-only";

        delta = {
          features = "line-numbers decorations";
          syntax-theme = delta-syntax-theme;
          decorations = {
            file-style = "omit";
            commit-decoration-style = "bold yellow box ul";
          };
        };

        merge.tool = "nvimdiff";

        user = {
          name = "Riccardo Mazzarini";
          email = "me@noib3.dev";
        };
      };

      signing = {
        key = "me@noib3.dev";
        signByDefault = true;
      };
    };
  };
}
