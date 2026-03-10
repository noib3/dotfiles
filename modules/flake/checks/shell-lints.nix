{
  inputs,
  ...
}:

{
  perSystem =
    { pkgs, ... }:
    {
      checks.shell-lints =
        pkgs.runCommand "check-shell-lints"
          {
            nativeBuildInputs = [
              pkgs.findutils
              pkgs.shellcheck
            ];
          }
          ''
            repo=${inputs.self}
            failed=0
            total_files=0

            while IFS= read -r file; do
              total_files=$((total_files + 1))
              rel_path="''${file#$repo/}"
              if ! shellcheck "$file"; then
                failed=1
              fi
            done < <(find "$repo" -type f -name "*.sh" | sort)

            if [ "$failed" -ne 0 ]; then
              exit 1
            fi

            printf "Checked %s shell files, no diagnostics.\n" "$total_files"
            touch "$out"
          '';
    };
}
