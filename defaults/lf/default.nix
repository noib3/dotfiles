{ pkgs }:

{
  settings = {
    dircounts = true;
    drawbox = true;
    hidden = true;
    ifs = "\\n";
    info = "size";
    period = 1;
    ratios = "1:2:2";
    shell = "bash";
    timefmt = "January 02, 2006 at 15:04:05";
  };

  commands = {
    open = ''
      ''${{
        text_files=()
        for f in $fx; do
          case $(file -Lb --mime-type $f) in
            text/*|application/json|inode/x-empty) text_files+=("$f");;
          esac
        done
        [[ ''${#text_files[@]} -eq 0 ]] || $EDITOR "''${text_files[@]}"
      }}
    '';

    touch = ''%touch "$@"; lf -remote "send $id select \"$@\""'';
    mkdir = ''%mkdir -p "$@"; lf -remote "send $id select \"$@\""'';
    give_ex = ''%chmod +x $fx; lf -remote "send $id reload"'';
    remove_ex = ''%chmod -x $fx; lf -remote "send $id reload"'';
    make_tarball = ''$tar -czvf "$@" "$fx"; lf -remote "send $id select \"$@\""'';

    fuzzy_cd = ''
      ''${{
        clear
        dirname="$(eval "$FZF_ALT_C_COMMAND" | eval "fzf $FZF_ALT_C_OPTS")" \
          && lf -remote "send $id cd \"~/''${dirname}\"" \
          || true
      }}
    '';

    fuzzy_edit = ''
      ''${{
        clear
        filenames=$(\
          fzf --multi --prompt='Edit> ' \
            | sed -r "s/\ /\\\ /g;s!(.*)!$HOME/\1!" \
            | tr '\n' ' ' \
            | sed 's/[[:space:]]*$//')
        [ ! -z "$filenames" ] \
          && $EDITOR "$filenames" \
          || true
      }}
    '';

    fuzzy_ripgrep = ''
      ''${{
        clear
        git status &>/dev/null
        [ $? == 0 ] \
          && dir="$(git rev-parse --show-toplevel)" \
          || dir="$(pwd)"
        rg_prefix="rg --column --color=always --"
        filenames=$(\
          eval "$rg_prefix \"\" $dir | sed \"s!$dir/!!\""  \
            | fzf --multi --prompt='Rg> ' --disabled --delimiter=: --with-nth=1,2,4 \
                --bind="change:reload($rg_prefix {q} $dir | sed \"s!$dir/!!\" || true)" \
                --preview="${builtins.toString ../neovim/lua/plugins/config/fzf/rg-previewer} $dir/{}" \
                --preview-window=+{2}-/2 --preview-window=border-left \
            | sed -r "s!^([^:]*):([^:]*):([^:]*):.*\$!$dir/\1!;s/\ /\\\ /g;" \
            | tr '\n' ' ' \
            | sed 's/[[:space:]]*$//')
        [ ! -z "$filenames" ] \
          && $EDITOR "$filenames" \
          || true
      }}
    '';
  };

  keybindings = {
    m = null;
    u = null;
    l = null;
    x = "cut";
    d = "delete";
    "<enter>" = "push $";
    t = "push :touch<space>";
    k = "push :mkdir<space>";
    "+" = "give_ex";
    "-" = "remove_ex";
    lg = "$lazygit";
    mtb = "push :make_tarball<space>.tar.gz<left><left><left><left><left><left><left>";
    "<c-x><c-d>" = "fuzzy_cd";
    "<c-x><c-e>" = "fuzzy_edit";
    "<c-x><c-r>" = "fuzzy_ripgrep";
  };

  cmdKeybindings = {
    "<up>" = "cmd-history-prev";
    "<down>" = "cmd-history-next";
  };

  previewer.source = ./previewer;

  extraConfig = "set cleaner ${builtins.toString ./cleaner}";
}
