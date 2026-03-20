{
  config,
  pkgs,
  lib,
  preferences,
}:

let
  profile = "Default";

  preferencesPath = "${config.home.homeDirectory}/Library/Application Support/BraveSoftware/Brave-Browser/${profile}/Preferences";

  prefUpdates = builtins.toJSON preferences;
in
''
  is_brave_running() {
    /usr/bin/pgrep -x "Brave Browser" > /dev/null 2>&1
  }

  apply_brave_preferences() {
    # Exit early if Preferences doesn't exist yet.
    [[ -f "${preferencesPath}" ]] || return 0

    # Generate the checksum of the preference updates.
    pref_hash=$(echo -n '${prefUpdates}' | ${pkgs.openssl}/bin/openssl dgst -sha256 | cut -d' ' -f2)
    hash_file="${config.xdg.cacheHome}/home-manager/brave-preferences.hash"

    # Exit early if the preferences haven't changed.
    if [[ -f "$hash_file" ]] && [[ "$(cat "$hash_file")" == "$pref_hash" ]]; then
      echo "Brave preferences already up to date"
      return 0
    fi

    # Brave writes the Preferences file on exit, so we need to quit it first.
    brave_was_running=0
    if is_brave_running; then
      brave_was_running=1
      run /usr/bin/osascript -e 'quit app "Brave Browser"'
      while is_brave_running; do /bin/sleep 0.5; done
    fi

    # Apply each preference update.
    run ${pkgs.jq}/bin/jq \
      --argjson updates '${prefUpdates}' \
      'reduce $updates[] as $update (.; setpath($update.path; $update.value))' \
      "${preferencesPath}" > "${preferencesPath}.tmp"

    run mv "${preferencesPath}.tmp" "${preferencesPath}"

    # Restart Brave if it was running.
    if [[ "$brave_was_running" -eq 1 ]]; then
      run /usr/bin/open -a "Brave Browser"
    fi

    # Store the hash.
    run mkdir -p "$(dirname "$hash_file")"
    run echo "$pref_hash" > "$hash_file"
  }

  apply_brave_preferences
''
