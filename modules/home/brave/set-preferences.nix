# A script that patches Brave's Preferences JSON file for a single profile.
# Quits and relaunches Brave if it's running.
{
  lib,
  jq,
  openssl,
  # ──
  preferencesPath,
  prefUpdates,
  hashFile,
  isDarwin,
  extraCommands ? "",
}:

let
  sha = lib.getExe' openssl "openssl";

  pgrep =
    if isDarwin then
      "/usr/bin/pgrep -x 'Brave Browser|Brave Browser.orig' "
    else
      "pgrep -x brave";

  quit =
    if isDarwin then
      ''/usr/bin/osascript -e 'quit app "Brave Browser"' ''
    else
      "pkill -TERM brave";

  relaunch = if isDarwin then ''/usr/bin/open -a "Brave Browser"'' else "brave &";
in
''
  _set_brave_preferences() {
    [[ -f "${preferencesPath}" ]] || return 0

    local pref_hash
    pref_hash=$(printf '%s' ${
      lib.escapeShellArg (prefUpdates + extraCommands)
    } | ${sha} dgst -sha256 | cut -d' ' -f2)

    if [[ -f "${hashFile}" ]] && [[ "$(cat "${hashFile}")" == "$pref_hash" ]]; then
      return 0
    fi

    local brave_was_running=0
    if ${pgrep} > /dev/null 2>&1; then
      brave_was_running=1
      ${quit}
      local attempts=0
      while ${pgrep} > /dev/null 2>&1; do
        if [[ "$attempts" -ge 60 ]]; then
          echo "Brave is still running; preferences were not changed" >&2
          return 1
        fi
        sleep 0.25
        attempts=$((attempts + 1))
      done
    fi

    ${extraCommands}

    run ${lib.getExe jq} \
      --argjson updates ${lib.escapeShellArg prefUpdates} \
      'reduce $updates[] as $update (.; setpath($update.path; $update.value))' \
      "${preferencesPath}" > "${preferencesPath}.tmp"

    run mv "${preferencesPath}.tmp" "${preferencesPath}"

    if [[ "$brave_was_running" -eq 1 ]]; then
      run ${relaunch}
    fi

    run mkdir -p "$(dirname "${hashFile}")"
    echo "$pref_hash" > "${hashFile}"
  }

  _set_brave_preferences
''
