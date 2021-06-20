{ pkgs }:

{
  settings = {
    dircounts = true;
    drawbox = true;
    hidden = true;
    icons = true;
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
        [ ''${#text_files[@]} -eq 0 ] || $EDITOR "''${text_files[@]}"
      }}
    '';

    touch = ''%touch "$@"; lf -remote "send $id select '$@'"'';
    mkdir = ''%mkdir -p "$@"; lf -remote "send $id select '$@'"'';
    give_ex = ''%chmod +x $fx; lf -remote "send $id reload"'';
    remove_ex = ''%chmod -x $fx; lf -remote "send $id reload"'';
    make_tarball = ''
      %{{
        dirname="$@"
        mkdir -p "$dirname"
        cp $fx "$dirname"
        tar -cvzf "$dirname.tar.gz" "$dirname"
        rm -rf "$dirname"
        lf -remote "send $id select '$dirname.tar.gz'"
      }}
    '';

    fuzzy_cd = ''
      ''${{
        clear
        dirname="$(eval "$FZF_ALT_C_COMMAND" | eval "fzf $FZF_ALT_C_OPTS")"
        [ -z "$dirname" ] || lf -remote "send $id cd '$HOME/$dirname'"
      }}
    '';

    fuzzy_edit = ''
      ''${{
        clear
        readarray -t filenames < <(\
          fzf --multi --prompt='Edit> ' \
            --preview='fzf-previewer ~/{}' \
            --preview-window=border-left \
            | sed -r "s!^!$HOME/!"
        )
        [ ''${#filenames[@]} -eq 0 ] || $EDITOR "''${filenames[@]}"
      }}
    '';

    fuzzy_ripgrep = ''$clear; fuzzy-ripgrep'';
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
    mtb = "push :make_tarball<space>";
    "<c-x><c-d>" = "fuzzy_cd";
    "<c-x><c-e>" = "fuzzy_edit";
    "<c-x><c-r>" = "fuzzy_ripgrep";
  };

  cmdKeybindings = {
    "<up>" = "cmd-history-prev";
    "<down>" = "cmd-history-next";
  };

  previewer.source = ./previewer.sh;

  extraConfig = "set cleaner ${builtins.toString ./cleaner.sh}";
}
