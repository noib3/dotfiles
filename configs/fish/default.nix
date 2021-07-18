{ pkgs, lib, colors }:

let
  cols = with lib;
    attrsets.mapAttrs
      (name: value: strings.removePrefix "#" value)
      colors;
in
{
  shellAliases = {
    cat = "bat";
    grep = "rg";
    ipython = "ipython --no-confirm-exit";
    ls = "ls -Alhv --color --file-type --group-directories-first --quoting-style=literal";
    wget = "wget --hsts-file=~/.cache/wget/wget-hsts";
  };

  shellAbbrs = {
    hmn = "home-manager news";
    hms = "home-manager switch";
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

    set fish_color_param ${cols.param}
    set fish_color_operator ${cols.operator}
    set fish_color_autosuggestion ${cols.autosuggestion} --italics
    set fish_color_comment ${cols.comment} --italics
    set fish_color_end ${cols.end}
    set fish_color_selection --background=${cols.selection-bg}

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

    # For some reason the pisces plugin needs to be sourced manually to become
    # active.
    source ~/.config/fish/conf.d/plugin-pisces.fish

    set -gx GPG_TTY (tty)
    ${pkgs.gnupg}/bin/gpg-connect-agent updatestartuptty /bye > /dev/null
  '';

  promptInit = ''
    ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
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
      set -l dirname (eval "$FZF_ALT_C_COMMAND" | eval "fzf $FZF_ALT_C_OPTS")
      test -z "$dirname" || cd "$HOME/$dirname"
      emit fish_prompt
      commandline -f repaint
    '';

    fuzzy_edit.body = ''
      set -l filenames (
        fzf --multi --prompt='Edit> ' --preview='previewer ~/{}' \
          | sed 's/\ /\\\ /g;s!^!~/!' \
          | tr '\n' ' ' \
          | sed 's/[[:space:]]*$//' \
      )
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
          | string collect \
      )
      test -z "$command" || commandline "$command"
      commandline -f repaint
    '';

    fuzzy_kill.body = ''
      set -l pgrep_prefix "pgrep -a -u "(whoami)
      set -l pids (
        eval "$pgrep_prefix" | sed 's/\(^[0-9]*\)/\x1b\[0;31m\1\x1b\[0m/' \
          | fzf \
              --multi --prompt='Kill> ' --disabled \
              --bind="change:reload($pgrep_prefix {q} | sed 's/\(^[0-9]*\)/\x1b\[0;31m\1\x1b\[0m/' || true)" \
          | sed -r 's/([0-9]+).*/\1/' \
          | tr '\n' ' ' \
          | sed 's/[[:space:]]*$//' \
      )
      test -z "$pids" || kill "$pids"
      commandline -f repaint
    '';

    fuzzy_ripgrep.body = ''
      fuzzy-ripgrep
      commandline -f repaint
    '';

    fuzzy_search.body = ''
      set -l filenames (
        fzf --multi --prompt='Paste> ' --preview='previewer ~/{}' \
          | sed 's/\ /\\\ /g;s!^!~/!' \
          | tr '\n' ' ' \
          | sed 's/[[:space:]]*$//' \
      )
      test -z "$filenames" || commandline --insert "$filenames"
      commandline -f repaint
    '';
  };
}
