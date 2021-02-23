{ pkgs }:

{
  shellAliases = {
    cat     = "bat";
    grep    = "grep --ignore-case --color=auto";
    ipython = "ipython --no-confirm-exit";
    ls      = "ls -Alhv --color --file-type --group-directories-first";
    wget    = "wget --hsts-file=~/.cache/wget/wget-hsts";
  };

  shellAbbrs = {
    ipy = "ipython";
    lg  = "lazygit";
    hms = "home-manager switch";
    hmn = "home-manager news";
  };

  plugins = [
    {
      name = "pisces";
      src  = pkgs.fetchFromGitHub {
        owner  = "laughedelic";
        repo   = "pisces";
        rev    = "v0.7.0";
        sha256 = "073wb83qcn0hfkywjcly64k6pf0d7z5nxxwls5sa80jdwchvd2rs";
      };
    }
  ];

  functions = {
    clear_no_scrollback.body = ''
      clear && printf "\e[3J"
      commandline --function repaint
    '';

    fuzzy_edit.body = ''
      set -l filenames (fzf --prompt="Edit> " --multi --height=8) \
        && set -l filenames (echo "~/"(string escape -- $filenames) \
                               | tr "\n" " " | sed 's/\s$//') \
        && commandline $EDITOR" "$filenames \
        && commandline --function execute
      commandline --function repaint
    '';

    fuzzy_cd.body = ''
      set -l dirname (eval (echo $FZF_ONLYDIRS_COMMAND) \
                        | fzf --prompt="Cd> " --height=8) \
        && cd $HOME/$dirname
      emit fish_prompt
      commandline -f repaint
    '';

    fuzzy_history.body = ''
      history merge
      set -l command_with_ts (
        history --null --show-time="%m/%e %H:%M:%S | " \
          | fzf --read0 --tiebreak=index --prompt="History> " --height=8 \
          | string collect) \
        && set -l command (string split -m1 " | " $command_with_ts)[2] \
        && commandline $command
      commandline --function repaint
    '';

    fuzzy_search.body = ''
      set -l filenames (fzf --prompt="Paste> " --multi --height=8) \
        && set -l filenames (echo "~/"(string escape -- $filenames) \
                               | tr "\n" " " | sed 's/\s$//') \
        && commandline --insert $filenames
      commandline --function repaint
    '';
  };
}
