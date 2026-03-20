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
}:

let
  sha = lib.getExe' openssl "openssl";

  pgrep =
    if isDarwin then ''/usr/bin/pgrep -x "Brave Browser"'' else "pgrep -x brave";

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
    pref_hash=$(echo -n '${prefUpdates}' | ${sha} dgst -sha256 | cut -d' ' -f2)

    if [[ -f "${hashFile}" ]] && [[ "$(cat "${hashFile}")" == "$pref_hash" ]]; then
      return 0
    fi

    local brave_was_running=0
    if ${pgrep} > /dev/null 2>&1; then
      brave_was_running=1
      ${quit}
      while ${pgrep} > /dev/null 2>&1; do sleep 0.5; done
    fi

    run ${lib.getExe jq} \
      --argjson updates '${prefUpdates}' \
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
