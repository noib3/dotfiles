#!/usr/bin/env bash

function polybar_autohide() {
  hideIt.sh \
    --name 'Polybar' \
    --region 0x0+1920+0 \
    --direction top \
    --peek 0 \
    --interval 0.25 \
    --steps 1
}

bspc subscribe node_remove \
  | while read line; do
      [ $(wmctrl -l | wc -l) != 0 ] || polybar_autohide &
    done
