# `/defaults/firefox`

Hi, this is my qutebrowser-inspired firefox setup. Here's a quick showdown of
its features:

| ![ddg-homepage](/.github/images/firefox/48o8mgrvihy51.png) |
|:--:|
| *DuckDuckGo homepage. The tab bar is hidden when only one tab is present* |
| ![navbar](/.github/images/firefox/1ohzbrrvihy51.png) |
| *Navbar with custom theme* |
| ![tabs](/.github/images/firefox/t0iethsvihy51.png) |
| *When multiple tabs are present they all take up the same amount of space and each of them is numbered* |
| ![tabbar-hidden](/.github/images/firefox/q5iao8tvihy51.png) |
| *The tab bar is hidden when the navbar is focused* |
| ![urls](/.github/images/firefox/0199t0svihy51.png) |
| ![bookmarks](/.github/images/firefox/fwf2b0tvihy51.png) |
| *Bookmarks are kept in the sidebar...* |
| ![bitwarden](/.github/images/firefox/a0aqbxsvihy51.png) |
| *...and so is Bitwarden, my password manager* |

# Additional settings

Most settings are set by the
[`profiles.home.settings`](https://github.com/noib3/dotfiles/blob/master/defaults/firefox/default.nix#L69-L91)
attribute inside the
[`default.nix`](https://github.com/noib3/dotfiles/blob/master/defaults/firefox/default.nix)
file, but a few others have to be set manually. In `about:preferences`:

1. General -> Default zoom -> 133%;
2. Privacy & Security -> Enhanced Tracking Protection -> Send websites a "Do
   Not Track" signal that you don’t want to be tracked -> check `Always`;
3. Privacy & Security -> Logins and Passwords -> uncheck `Ask to save logins
   and passwords for websites`;
4. Privacy & Security -> Firefox Data Collection and Use -> uncheck everything;
5. Privacy & Security -> HTTPS-Only Mode -> check `Enable HTTPS-Only Mode in
   all windows`.

Also, enable all the installed extensions in `about:addons`.
