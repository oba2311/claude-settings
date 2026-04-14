#!/bin/sh
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Session quota: matches the "Current session X% used" shown in /status dialog.
# Prefers the 5-hour rolling window; falls back to the 7-day window if absent.
session_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // .rate_limits.seven_day.used_percentage // empty')

# Reset timestamp: prefer five_hour window, fall back to seven_day
resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // .rate_limits.seven_day.resets_at // empty')

# Shorten home directory to ~
cwd=$(echo "$cwd" | sed "s|^$HOME|~|")

# Build context segment
if [ -n "$used" ]; then
  ctx_str=$(printf "ctx:%.0f%%" "$used")
else
  ctx_str="ctx:--"
fi

# Build session quota segment (mirrors /status "Current session X% used")
if [ -n "$session_pct" ]; then
  tok_str=$(printf "tokens:%.0f%%" "$session_pct")
else
  tok_str=""
fi

# Build reset countdown segment
reset_str=""
if [ -n "$resets_at" ]; then
  now=$(date +%s)
  diff=$((resets_at - now))
  if [ "$diff" -gt 0 ]; then
    hours=$((diff / 3600))
    mins=$(((diff % 3600) / 60))
    if [ "$hours" -gt 0 ]; then
      reset_str=$(printf "resets:%dh%dm" "$hours" "$mins")
    else
      reset_str=$(printf "resets:%dm" "$mins")
    fi
  else
    reset_str="resets:now"
  fi
fi

# Assemble status line
line=$(printf "\033[0;36m%s\033[0m  \033[0;33m%s\033[0m  \033[0;32m%s\033[0m" "$model" "$cwd" "$ctx_str")
if [ -n "$tok_str" ]; then
  line=$(printf "%s  \033[0;35m%s\033[0m" "$line" "$tok_str")
fi
if [ -n "$reset_str" ]; then
  line=$(printf "%s  \033[2;34m%s\033[0m" "$line" "$reset_str")
fi
printf "%s" "$line"
