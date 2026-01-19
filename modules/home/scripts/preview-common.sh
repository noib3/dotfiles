is_ssh_private_key() {
  local desc="${1:-}"

  echo "$desc" | grep -qiE '(openssh private key|pem .* private key)'
}

show_pgp_public_key() {
  local file="$1"
  local mime_type="$2"

  if [ "$mime_type" = "application/pgp-keys" ] || [ "$mime_type" = "application/pgp" ]; then
    gpg --batch --show-keys --with-fingerprint "$file" 2>/dev/null
    return $?
  fi

  if [ "$mime_type" = "text/plain" ] && grep -q "BEGIN PGP PUBLIC KEY BLOCK" -- "$file"; then
    gpg --batch --show-keys --with-fingerprint "$file" 2>/dev/null
    return $?
  fi

  return 1
}
