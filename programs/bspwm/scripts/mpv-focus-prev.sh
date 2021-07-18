# Focus the last visited desktop after an mpv node is closed.
#
# Taken from https://www.reddit.com/r/bspwm/comments/ocwf5y/how_to_execute_a_command_when_a_specific_program/h3xpcn9?utm_source=share&utm_medium=web2x&context=3

mapfile -t mpv_ids < <(xdo id -Nmpv)

while IFS=' ' read -r event_type _ _ nid; do
    case "$event_type" in
        node_remove)
            for mpv_id in "${mpv_ids[@]}"; do
                (( mpv_id == nid )) \
                    || continue
                bspc desktop -f last
                break
            done
            ;&
        node_add)
            mapfile -t mpv_ids < <(xdo id -Nmpv)
            ;;
    esac
done < <(bspc subscribe node_{add,remove})
