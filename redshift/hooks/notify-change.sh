#!/usr/bin/env sh

case $1 in
    period-changed)
        if [ ! "$3" = "none" ]; then
            osascript -e "display notification \"Switching to $3 temps...\" with title \"Redshift\""
        fi
esac
