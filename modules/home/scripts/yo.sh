prompt_args=()
if (($# > 0)); then
  prompt_args=("$*")
fi

exec codex exec \
  --ephemeral \
  --model gpt-5.6-luna \
  --config model_reasoning_effort=high \
  --config service_tier=fast \
  "${prompt_args[@]}"
