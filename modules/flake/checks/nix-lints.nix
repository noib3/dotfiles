{
  inputs,
  ...
}:

{
  perSystem =
    { pkgs, ... }:
    {
      checks.nix-lints =
        pkgs.runCommand "check-nix-lints"
          {
            nativeBuildInputs = [
              pkgs.findutils
              pkgs.jq
              pkgs.nixf
            ];
          }
          ''
            repo=${inputs.self}
            suppressed='["sema-primop-removed-prefix"]'
            failed=0
            total_files=0
            total_diagnostics=0

            while IFS= read -r file; do
              total_files=$((total_files + 1))
              raw_diagnostics="$(nixf-tidy --variable-lookup < "$file")"
              diagnostics="$(printf '%s\n' "$raw_diagnostics" | jq --argjson suppressed "$suppressed" '
                [ .[] | select((.sname as $s | ($suppressed | index($s))) | not) ]
              ')"
              if [ "$diagnostics" != "[]" ]; then
                rel_path="''${file#$repo/}"
                diag_count="$(printf '%s\n' "$diagnostics" | jq 'length')"
                total_diagnostics=$((total_diagnostics + diag_count))

                printf "\n%s (%s diagnostics)\n" "$rel_path" "$diag_count"
                printf '%s\n' "$diagnostics" | jq -r '
                  .[]
                  | "  - [\(.sname)] \(.range.lCur.line):\(.range.lCur.column) \(.message)",
                    (if (.fixes | length) > 0
                     then (.fixes[] | "      fix: \(.message)")
                     else "      fix: (no automatic fix available)"
                     end)
                '
                failed=1
              fi
            done < <(find "$repo" -type f -name "*.nix" | sort)

            if [ "$failed" -ne 0 ]; then
              printf "\nFound %s diagnostics in %s Nix files.\n" "$total_diagnostics" "$total_files"
              exit 1
            fi

            printf "Checked %s Nix files, no diagnostics.\n" "$total_files"
            touch "$out"
          '';
    };
}
