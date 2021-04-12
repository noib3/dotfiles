{ pkgs, colors }:

{
  shellAliases = {
    ls = "ls -Alhv --color --file-type --group-directories-first --quoting-style=literal";
    wget = "wget --hsts-file=~/.cache/wget/wget-hsts";
    grep = "grep --ignore-case --color=auto";
    ipython = "ipython --no-confirm-exit";
    cat = "bat";
  };

  shellAbbrs = {
    hms = "home-manager switch";
    hmn = "home-manager news";
    ipy = "ipython";
    lg = "lazygit";
  };

  interactiveShellInit = ''
    set fish_greeting ""

    set fish_cursor_default block
    set fish_cursor_insert line
    set fish_cursor_replace_one underscore
    set fish_cursor_visual block

    set fish_color_user green
    set fish_color_host white
    set fish_color_host_remote white
    set fish_color_cwd blue
    set fish_color_command green
    set fish_color_error red
    set fish_color_quote yellow
    set fish_color_valid_path --underline
    set fish_color_redirection white

    set fish_color_param ${colors.param}
    set fish_color_operator ${colors.operator}
    set fish_color_autosuggestion ${colors.autosuggestion} --italics
    set fish_color_comment ${colors.comment} --italics
    set fish_color_end ${colors.end}
    set fish_color_selection --background=${colors.selection_bg}

    fish_vi_key_bindings

    bind \cA beginning-of-line
    bind \cE end-of-line
    bind yy fish_clipboard_copy
    bind Y fish_clipboard_copy
    bind p fish_clipboard_paste

    bind -M visual \cA beginning-of-line
    bind -M visual \cE end-of-line

    bind -M insert \cA beginning-of-line
    bind -M insert \cE end-of-line
    bind -M insert \e\x7F backward-kill-word
    bind -M insert \cW exit
    bind -M insert \cG clear_no_scrollback
    bind -M insert \cX\cD fuzzy_cd
    bind -M insert \cX\cE fuzzy_edit
    bind -M insert \cX\cF fuzzy_history
    bind -M insert \cX\cG fuzzy_kill
    bind -M insert \cX\cR fuzzy_ripgrep
    bind -M insert \cS fuzzy_search
  '' +
  ''
    # For some reason the pisces plugin needs to be sourced manually to become
    # active.
    source ~/.config/fish/conf.d/plugin-pisces.fish
  '' +
  ''
    set -gx GPG_TTY (tty)
    ${pkgs.gnupg}/bin/gpg-connect-agent updatestartuptty /bye > /dev/null
  '';

  plugins = [
    {
      name = "pisces";
      src = pkgs.fetchFromGitHub {
        owner = "laughedelic";
        repo = "pisces";
        rev = "v0.7.0";
        sha256 = "073wb83qcn0hfkywjcly64k6pf0d7z5nxxwls5sa80jdwchvd2rs";
      };
    }
  ];

  functions = {
    clear_no_scrollback.body = ''
      clear && printf "\e[3J"
      commandline -f repaint
    '';

    fuzzy_cd.body = ''
      set -l dirname (eval "$FZF_ALT_C_COMMAND | fzf $FZF_ALT_C_OPTS") \
        && cd "$HOME/$dirname"
      emit fish_prompt
      commandline -f repaint
    '';

    fuzzy_edit.body = ''
      set -l filenames (
        fzf --multi --prompt='Edit> ' \
          | sed -r 's/\ /\\\ /g;s!(.*)!~/\1!' \
          | tr '\n' ' ' \
          | sed 's/[[:space:]]*$//')
      test ! -z "$filenames" \
        && commandline "$EDITOR $filenames" \
        && commandline -f execute
      commandline -f repaint
    '';

    fuzzy_history.body = ''
      history merge
      set -l command (
        history --null --show-time="%B %d %T " \
          | sed -z 's/\(^.*[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\)/\x1b\[0;31m\1\x1b\[0m/g' \
          | fzf --read0 --tiebreak=index --prompt='History> ' --query=(commandline) \
          | sed 's/^.*[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\} //' \
          | string collect) \
        && commandline "$command"
      commandline -f repaint
    '';

    fuzzy_kill.body = ''
      set -l pgrep_prefix "pgrep -a -u "(whoami)
      set -l pids (
        eval "$pgrep_prefix" | sed 's/\(^[0-9]*\)/\x1b\[0;31m\1\x1b\[0m/' \
          | fzf --multi --prompt='Kill> ' --disabled \
              --bind="change:reload($pgrep_prefix {q} | sed 's/\(^[0-9]*\)/\x1b\[0;31m\1\x1b\[0m/' || true)" \
          | sed -r 's/([0-9]+).*/\1/' \
          | tr '\n' ' ' \
          | sed 's/[[:space:]]*$//') \
        && kill $pids
      commandline -f repaint
    '';

    fuzzy_ripgrep.body = ''
      git status &>/dev/null
      test $status -eq 0 \
        && set -l dir (git rev-parse --show-toplevel) \
        || set -l dir (pwd)
      set -l rg_prefix \
        "rg --smart-case --column --line-number --no-heading --color=always --"
      set -l filenames (
        eval "$rg_prefix \"\" $dir | sed \"s!$dir/!!\""  \
          | fzf --multi --prompt='Rg> ' --phony --delimiter=: --with-nth=1,2,4 \
              --bind="change:reload($rg_prefix {q} $dir | sed \"s!$dir/!!\" || true)" \
              --preview="${builtins.toString ../neovim/lua/plugins/config/fzf/rg-previewer} $dir/{}" \
              --preview-window=+{2}-/2 \
          | sed -r "s!^([^:]*):([^:]*):([^:]*):.*\$!$dir/\1!;s/\ /\\\ /g;s!$HOME!~!" \
          | tr '\n' ' ' \
          | sed 's/[[:space:]]*$//')
      test ! -z "$filenames" \
        && commandline "$EDITOR $filenames" \
        && commandline -f execute
      commandline -f repaint
    '';

    fuzzy_search.body = ''
      set -l filenames (
        fzf --multi --prompt='Paste> ' \
          | sed -r 's/\ /\\\ /g;s/(.*)/~\/\1/' \
          | tr '\n' ' ' \
          | sed 's/[[:space:]]*$//')
      test ! -z "$filenames" \
        && commandline --insert "$filenames"
      commandline -f repaint
    '';
  };
}
