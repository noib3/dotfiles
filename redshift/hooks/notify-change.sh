#!/usr/bin/env sh

# The first parameter indicates the event
case $1 in
    period-changed)
        # The second and third parameters are the old and the new periods.
        # Their values can be 'night', 'daytime' and 'transition'.
        if [ ! "$3" = "none" ]; then
            # Capitalize the period, then use sed to convert 'Night' and
            # 'Daytime' into 'Night time' and 'Day time'.
            period=$(echo $(tr '[:lower:]' '[:upper:]' <<< ${3:0:1})${3:1} |
                            \ sed 's/time//;s/$/ time/')
            /usr/local/bin/terminal-notifier -title "Redshift" \
                                             -subtitle "Switching temps..." \
                                             -message "$period" \
                                             -appIcon $(dirname "$0")/Redshift_logo.png
        fi
esac
