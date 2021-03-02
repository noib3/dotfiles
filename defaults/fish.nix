{ pkgs, theme }:

let
  colors = import (../themes + "/${theme}" + /fish.nix);
in

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

  interactiveShellInit = ''
    bass source ~/.nix-profile/etc/profile.d/nix{,-daemon}.sh 2>/dev/null \
      || true

    set fish_greeting

    set fish_cursor_default     block
    set fish_cursor_insert      line
    set fish_cursor_replace_one underscore
    set fish_cursor_visual      block

    set fish_color_user        green
    set fish_color_host        white
    set fish_color_host_remote white
    set fish_color_cwd         blue
    set fish_color_command     green
    set fish_color_error       red
    set fish_color_quote       yellow
    set fish_color_valid_path  --underline
    set fish_color_redirection white

    set fish_color_param          ${colors.param}
    set fish_color_operator       ${colors.operator}
    set fish_color_autosuggestion ${colors.autosuggestion} --italics
    set fish_color_comment        ${colors.comment} --italics
    set fish_color_end            ${colors.end}
    set fish_color_selection      --background=${colors.selection_bg}

    fish_vi_key_bindings

    bind \cA beginning-of-line
    bind \cE end-of-line
    bind yy  fish_clipboard_copy
    bind Y   fish_clipboard_copy
    bind p   fish_clipboard_paste

    bind -M visual \cA beginning-of-line
    bind -M visual \cE end-of-line

    bind -M insert \cA    beginning-of-line
    bind -M insert \cE    end-of-line
    bind -M insert \e\x7F backward-kill-word
    bind -M insert \cW    exit
    bind -M insert \cX\cD fuzzy_cd
    bind -M insert \cX\cE fuzzy_edit
    bind -M insert \cX\cF fuzzy_history
    bind -M insert \cS    fuzzy_search
    bind -M insert \cG    clear_no_scrollback

    function __reset_cursor_line --on-event="fish_prompt"
      printf "\e[5 q"
    end

    set dircolor \
      (echo $LS_COLORS | sed 's/\(^\|.*:\)di=\([^:]*\).*/\2/')
    set fgodcolor \
      (echo $LS_COLORS | sed 's/\(^\|.*:\)\*\.fgod=\([^:]*\).*/\2/')

    set FZF_DEFAULT_COMMAND_EXT \
      "| sed 's/\x1b\["$dircolor"m/\x1b\["$fgodcolor"m/g'"
    set FZF_ONLYDIRS_COMMAND_EXT $FZF_DEFAULT_COMMAND_EXT \
      "| sed 's/\(.*\)\x1b\["$fgodcolor"m/\1\x1b\["$dircolor"m/'"

    set -x FZF_DEFAULT_COMMAND $FZF_DEFAULT_COMMAND $FZF_DEFAULT_COMMAND_EXT
    set -x FZF_ONLYDIRS_COMMAND $FZF_ONLYDIRS_COMMAND $FZF_ONLYDIRS_COMMAND_EXT

    direnv hook fish | source
  '';

  plugins = [
    {
      name = "bass";
      src = pkgs.fetchFromGitHub {
        owner  = "edc";
        repo   = "bass";
        rev    = "2fd3d2157d5271ca3575b13daec975ca4c10577a";
        sha256 = "0mb01y1d0g8ilsr5m8a71j6xmqlyhf8w4xjf00wkk8k41cz3ypky";
      };
    }
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
