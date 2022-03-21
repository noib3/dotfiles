{ colorscheme
, palette
, removePrefix
}:

let
  colors =
    builtins.mapAttrs
      (name: hex: removePrefix "#" hex)
      (import ./colors.nix { inherit colorscheme palette; });
in
{
  filetypes = {
    core = {
      regular_file = [ "$fi" ];
      directory = [ "$di" ];
      executable_file = [ "$ex" ];
      symlink = [ "$ln" ];
      broken_symlink = [ "$or" ];
      missing_symlink_target = [ "$mi" ];
      fifo = [ "$pi" ];
      socket = [ "$so" ];
      character_device = [ "$cd" ];
      block_device = [ "$bd" ];
      normal_text = [ "$no" ];
      sticky = [ "$st" ];
      other_writable = [ "$ow" ];
      sticky_other_writable = [ "$tw" ];
    };

    text = {
      readme = [ "README.md" ];
      todo = [
        "TODO"
        "TODO.md"
        "TODO.txt"
      ];
      licenses = [ "LICENSE" ];
      configuration = [
        ".conf"
        ".json"
        ".yml"
        ".toml"
      ];
      bibtex = [ ".bib" ];
      other = [ ".txt" ];
    };

    markup = {
      web = [ ".html" ];
      other = [
        ".md"
        ".Rmd"
        ".xml"
      ];
    };

    programming = {
      source = {
        css = [ ".css" ];
        go = [ ".go" ];
        ipython = [ ".ipynb" ];
        javascript = [ ".js" ];
        lua = [ ".lua" ];
        latex = {
          regular = [ ".tex" ];
          class = [ ".cls" ];
          package = [ ".sty" ];
          special = [ "main.tex" ];
        };
        ocaml = [ ".ml" ];
        nix = [ ".nix" ];
        python = [ ".py" ];
        kotlin = [ ".kt" ];
        dart = [ ".dart" ];
        r = [ ".r" ];
        rust = [ ".rs" ];
        shell = [
          ".sh"
          ".bash"
          ".zsh"
          ".fish"
        ];
        viml = [
          ".vim"
          ".snippets"
        ];
      };

      tooling = {
        git = [
          ".gitignore"
          ".gitmodules"
          ".gitattributes"
          ".gitconfig"
        ];
        build = [
          ".cmake"
          "Makefile"
          ".make"
        ];
        packaging = [
          "MANIFEST.in"
          "setup.py"
        ];
      };
    };

    media = {
      image = [
        ".eps"
        ".gif"
        ".jpeg"
        ".jpg"
        ".png"
        ".svg"
      ];
      audio = [
        ".flac"
        ".mp3"
        ".ogg"
        ".wav"
      ];
      video = [
        ".mkv"
        ".mp4"
        ".mov"
        ".avi"
      ];
    };

    office = {
      document = [ ".pdf" ".epub" ];
    };

    archives = {
      images = [
        ".dmg"
        ".img"
        ".iso"
      ];
      other = [
        ".gz"
        ".pkg"
        ".tar"
        ".zip"
      ];
    };

    unimportant = {
      editor = [ ".lvimrc" ];
      dropbox = [ ".dropbox" ];
      lock = [ ".lock" ];
      build_artifacts = {
        latex = [
          ".aux"
          ".bbl"
          ".bcf"
          ".blg"
          ".loe"
          ".log"
          ".out"
          ".run.xml"
          ".synctex(busy)"
          ".synctex.gz"
          ".toc"
        ];
      };
    };
  };

  themes = {
    current = {
      inherit colors;

      core = {
        regular_file = { };

        directory = {
          foreground = "blue";
          font-style = "bold";
        };

        executable_file = {
          foreground = "green";
          font-style = "bold";
        };

        symlink = {
          foreground = "cyan";
        };

        broken_symlink = {
          foreground = "black";
          background = "red";
        };

        missing_symlink_target = {
          foreground = "black";
          background = "red";
        };

        fifo = {
          foreground = "black";
          background = "blue";
        };

        socket = {
          foreground = "black";
          background = "orange";
        };

        character_device = {
          foreground = "black";
          background = "cyan";
        };

        block_device = {
          foreground = "black";
          background = "red";
        };

        normal_text = { };
        sticky = { };
        sticky_other_writable = { };
        other_writable = { };
      };

      markup = {
        foreground = "yellow";
      };

      text = {
        foreground = "yellow";
        licenses = { };
        readme = {
          foreground = "yellow";
          font-style = "underline";
        };
      };

      programming = {
        source = {
          foreground = "magenta";
          dart = {
            foreground = "blue";
          };
          kotlin = {
            foreground = "orange";
          };
          latex = {
            foreground = "magenta";
            special = {
              font-style = "underline";
              foreground = "cyan";
            };
          };
        };

        tooling = {
          foreground = "gray";
          continuous-integration = {
            foreground = "gray";
          };
        };
      };

      media = {
        image = {
          foreground = "orange";
        };

        audio = {
          foreground = "orange";
        };

        video = {
          foreground = "cyan";
        };
      };

      office = {
        foreground = "cyan";
      };

      archives = {
        foreground = "red";
      };

      executable = {
        foreground = "red";
        font-style = "bold";
      };

      unimportant = {
        foreground = "gray";
      };
    };
  };
}
