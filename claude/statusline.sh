#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract fields from JSON
cwd=$(echo "$input" | jq -r '.cwd')
model=$(echo "$input" | jq -r '.model.display_name')
input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

# Message tokens only (input + output)
msg_tokens=$((input_tokens + output_tokens))
# Format as "Xk"
if [ "$msg_tokens" -ge 1000 ]; then
  msg_display="$((msg_tokens / 1000))k"
else
  msg_display="$msg_tokens"
fi

# Fixed username
user="kraitsura"

# Determine if we're on a remote server or container
get_location() {
  if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]; then
    hostname -s
    return
  fi
  if [ -f /.dockerenv ] || grep -q 'docker\|lxc\|kubepod' /proc/1/cgroup 2>/dev/null; then
    hostname -s
    return
  fi
  echo "home"
}

# Get tmux info if in tmux
get_tmux_info() {
  if [ -n "$TMUX" ]; then
    session=$(tmux display-message -p '#S' 2>/dev/null)
    window=$(tmux display-message -p '#W' 2>/dev/null)
    if [ -n "$session" ] && [ -n "$window" ]; then
      echo " [${session}:${window}]"
    fi
  fi
}

# Get git info
get_git_info() {
  cd "$1" 2>/dev/null || return
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    return
  fi
  branch=$(git branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git rev-parse --short HEAD 2>/dev/null)
  if ! git diff-index --quiet HEAD -- 2>/dev/null || \
     [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
    echo " ($branch*)"
  else
    echo " ($branch)"
  fi
}

# Build components
location=$(get_location)
tmux_info=$(get_tmux_info)
dir=$(basename "$cwd")
git_info=$(get_git_info "$cwd")

# Output
printf "%s@%s%s:%s%s | %s | msgs:%s" "$user" "$location" "$tmux_info" "$dir" "$git_info" "$model" "$msg_display"
