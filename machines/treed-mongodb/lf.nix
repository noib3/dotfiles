{
  commands = {
    open = ''
      ''${{
        text_files=()
        for f in $fx; do
          case $(file -b --mime-type $f) in
            text/*|application/json|inode/x-empty) text_files+=("$f");;
          esac
        done
        [[ ''${#text_files[@]} -eq 0 ]]  || $EDITOR "''${text_files[@]}"
      }}
    '';
  };
}
