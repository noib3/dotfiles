#!/usr/bin/env sh

# Filename:   redshift/hooks/notify-change.sh
# Github:     https://github.com/n0ibe/macOS-dotfiles
# Maintainer: Riccardo Mazzarini

# The first parameter indicates the event
case $1 in
    period-changed)
        # The second and third parameters are the old and the new periods
        # The values can be 'night', 'daytime' and 'transition'
        if [ ! "$3" = "none" ]; then
            # Capitalize the period, then use sed to convert 'Night' and 'Daytime'
            # to 'Night time' and 'Day time'
            period=$(echo $(tr '[:lower:]' '[:upper:]' <<< ${3:0:1})${3:1} | sed 's/time//;s/$/ time/')
            /usr/local/bin/terminal-notifier -title "Redshift" \
                                             -subtitle "Switching temps..." \
                                             -message "$period" \
                                             -appIcon $(dirname "$0")/Redshift-logo.png
        fi
esac
