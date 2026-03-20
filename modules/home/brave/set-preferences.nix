# Returns a bash script that patches Brave's Preferences JSON file for a
# single profile using jq.  Skips the update when the file doesn't exist
# yet or when nothing has changed (hash-based).
{
  lib,
  jq,
  openssl,
  # ──
  preferencesPath,
  prefUpdates,
  hashName,
  cacheHome,
  isDarwin,
}:

let
  pgrep = if isDarwin then ''/usr/bin/pgrep -x "Brave Browser"'' else "pgrep -x brave";

  quit =
    if isDarwin then ''/usr/bin/osascript -e 'quit app "Brave Browser"' '' else "pkill -TERM brave";

  relaunch = if isDarwin then ''/usr/bin/open -a "Brave Browser"'' else "brave &";
in
''
  is_brave_running() {
    ${pgrep} > /dev/null 2>&1
  }

  quit_brave() {
    ${quit}
    while is_brave_running; do sleep 0.5; done
  }

  relaunch_brave() {
    run ${relaunch}
  }

  apply_brave_preferences() {
    # Exit early if Preferences doesn't exist yet.
    [[ -f "${preferencesPath}" ]] || return 0

    # Generate the checksum of the preference updates.
    pref_hash=$(echo -n '${prefUpdates}' | ${lib.getExe' openssl "openssl"} dgst -sha256 | cut -d' ' -f2)
    hash_file="${cacheHome}/home-manager/${hashName}.hash"

    # Exit early if the preferences haven't changed.
    if [[ -f "$hash_file" ]] && [[ "$(cat "$hash_file")" == "$pref_hash" ]]; then
      return 0
    fi

    # Brave writes the Preferences file on exit, so we need to quit it
    # first.
    brave_was_running=0
    if is_brave_running; then
      brave_was_running=1
      quit_brave
    fi

    # Apply each preference update.
    run ${lib.getExe jq} \
      --argjson updates '${prefUpdates}' \
      'reduce $updates[] as $update (.; setpath($update.path; $update.value))' \
      "${preferencesPath}" > "${preferencesPath}.tmp"

    run mv "${preferencesPath}.tmp" "${preferencesPath}"

    # Restart Brave if it was running.
    if [[ "$brave_was_running" -eq 1 ]]; then
      relaunch_brave
    fi

    # Store the hash.
    run mkdir -p "$(dirname "$hash_file")"
    run echo "$pref_hash" > "$hash_file"
  }

  apply_brave_preferences
''
