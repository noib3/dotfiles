usage() {
  echo "usage: $0 [block|unblock] <domain>"
}

block() {
  local DOMAIN="$1"

  iptables \
    -A OUTPUT -p tcp -m string --string "$DOMAIN" \
    --algo kmp -j REJECT

  echo "Blocked $DOMAIN"
}

unblock() {
  local DOMAIN="$1"

  local RULE_NUMBERS

  RULE_NUMBERS=$(\
    iptables -L OUTPUT --line-numbers \
      | jc --iptables \
      | jq ".[] | select(.chain == \"OUTPUT\") | .rules[]" \
      | jq "select(.target == \"REJECT\" and (.options | contains(\"STRING match  \\\"$DOMAIN\\\"\")))" \
      | jq ".num" \
  )

  if [ -n "$RULE_NUMBERS" ]; then
    # Delete each rule by number
    for RULE_NUMBER in $RULE_NUMBERS; do
        iptables -D OUTPUT "$RULE_NUMBER"
    done
    echo "Unblocked $DOMAIN"
  else
    echo "$DOMAIN is not blocked"
    exit 1
  fi
}

if [[ $(id -u) -ne 0 ]]; then
    echo "needs to be running as root"
    exit 1
fi

if [[ $# -ne 2 ]]; then
    usage
    exit 1
fi

ACTION="$1"
DOMAIN="$2"

case "$ACTION" in
  block)
    block "$DOMAIN"
    ;;
  unblock)
    unblock "$DOMAIN"
    ;;
  *)
    usage
    exit 1
    ;;
esac
