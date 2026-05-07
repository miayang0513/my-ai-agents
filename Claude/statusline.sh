#!/usr/bin/env bash
# Claude Code status line — two-line layout
# Line 1: 📁 path | model | bar used% | rate-limit buckets
# Line 2: session | +adds/-removes

input=$(cat)

model_raw=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
session_name=$(echo "$input" | jq -r '.session_name // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')
cwd_path=$(echo "$input" | jq -r '.workspace.current_dir // empty')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // empty')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // empty')

RESET='\033[0m'
DIM='\033[2m'
CYAN='\033[96m'
GREEN='\033[92m'
YELLOW='\033[93m'
RED='\033[91m'
GREY='\033[90m'
WHITE='\033[97m'

# --- helpers ---

# Shorten "Claude Opus 4.7 (1M context)" → "Opus 4.7": strip "Claude " prefix
# and any trailing parenthetical like "(1M context)".
shorten_model() {
  echo "$1" | sed -e 's/^Claude[[:space:]]*//' -e 's/[[:space:]]*([^)]*)[[:space:]]*$//'
}

# Build a 10-cell bar: zone-based coloring (Option A) so at 64% (6 filled) you
# see 3 bright-green + 2 bright-yellow + 1 bright-red + 3 dark-grey cells.
#   cells 1-3  (zones 0-30%) → bright green
#   cells 4-5  (zones 30-50%)→ bright yellow
#   cells 6-7  (zones 50-70%)→ bright red
#   cells 8-10 (zones 70-100%)→ always dim grey (unfilled tail color)
# Filled cells render in their zone color; unfilled cells render dim grey.
make_bar() {
  local pct=$1
  local width=10
  local filled=$(( pct * width / 100 ))
  local bar=""
  for (( i=1; i<=width; i++ )); do
    if   (( i <= 3 )); then color="$GREEN"
    elif (( i <= 5 )); then color="$YELLOW"
    elif (( i <= 7 )); then color="$RED"
    else                    color="$GREY"
    fi
    if (( i <= filled )); then
      bar="${bar}${color}█${RESET}"
    else
      bar="${bar}${GREY}█${RESET}"
    fi
  done
  printf "%b" "$bar"
}

# Convert a future Unix epoch into compact "1H8m" / "45m" / "19H8m" format.
# Returns empty string if resets_at is empty or in the past.
time_until() {
  local resets_at=$1
  [ -z "$resets_at" ] && return
  local now
  now=$(date +%s)
  local secs=$(( resets_at - now ))
  (( secs <= 0 )) && return
  local h=$(( secs / 3600 ))
  local m=$(( (secs % 3600) / 60 ))
  if (( h > 0 )); then
    printf "%dH%dm" "$h" "$m"
  else
    printf "%dm" "$m"
  fi
}

# Color a percentage value: red >75%, yellow >50%, default otherwise.
color_pct() {
  local pct_int=$1
  if   (( pct_int > 75 )); then printf "%b%d%%%b" "$RED"    "$pct_int" "$RESET"
  elif (( pct_int > 50 )); then printf "%b%d%%%b" "$YELLOW" "$pct_int" "$RESET"
  else                          printf "%b%d%%%b" "$GREEN"  "$pct_int" "$RESET"
  fi
}

# Join an array with a dim pipe separator.
join_parts() {
  local sep
  sep="$(printf "${DIM} | ${RESET}")"
  local result=""
  for part in "$@"; do
    if [ -z "$result" ]; then
      result="$part"
    else
      result="${result}${sep}${part}"
    fi
  done
  printf "%b" "$result"
}

# --- LINE 1 ---
line1_parts=()

# 1. Path with folder icon: cwd relative to project_dir, or fallback
if [ -n "$cwd_path" ] && [ -n "$project_dir" ]; then
  proj_base=$(basename "$project_dir")
  if [ "$cwd_path" = "$project_dir" ]; then
    display_path="$proj_base"
  elif [[ "$cwd_path" == "$project_dir"/* ]]; then
    rel="${cwd_path#"$project_dir"/}"
    display_path="${proj_base}/${rel}"
  else
    display_path="${project_dir} | ${cwd_path}"
  fi
  line1_parts+=("$(printf "📁 ${WHITE}%s${RESET}" "$display_path")")
elif [ -n "$cwd_path" ]; then
  line1_parts+=("$(printf "📁 ${WHITE}%s${RESET}" "$cwd_path")")
fi

# 2. Model (short form)
if [ -n "$model_raw" ]; then
  short=$(shorten_model "$model_raw")
  line1_parts+=("$(printf "${CYAN}%s${RESET}" "$short")")
fi

# 3. Gradient bar + used%
if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  bar=$(make_bar "$used_int")
  line1_parts+=("$(printf "%b %d%%" "$bar" "$used_int")")
fi

# 4a. 5-hour rate limit bucket
if [ -n "$five_pct" ]; then
  five_int=$(printf '%.0f' "$five_pct")
  time_str=$(time_until "$five_reset")
  colored_pct=$(color_pct "$five_int")
  if [ -n "$time_str" ]; then
    line1_parts+=("$(printf "%s %b" "$time_str" "$colored_pct")")
  else
    line1_parts+=("$(printf "%b" "$colored_pct")")
  fi
fi

# 4b. 7-day rate limit bucket
if [ -n "$seven_pct" ]; then
  seven_int=$(printf '%.0f' "$seven_pct")
  time_str=$(time_until "$seven_reset")
  colored_pct=$(color_pct "$seven_int")
  if [ -n "$time_str" ]; then
    line1_parts+=("$(printf "%s %b" "$time_str" "$colored_pct")")
  else
    line1_parts+=("$(printf "%b" "$colored_pct")")
  fi
fi

# --- LINE 2 ---
line2_parts=()

# 5. Session: prefer session_name, fall back to first 8 chars of session_id
if [ -n "$session_name" ]; then
  line2_parts+=("$(printf "${DIM}%s${RESET}" "$session_name")")
elif [ -n "$session_id" ]; then
  short_id="${session_id:0:8}"
  line2_parts+=("$(printf "${DIM}%s${RESET}" "$short_id")")
fi

# 6. Lines added/removed — hidden if both zero or absent
if [ -n "$lines_added" ] && [ -n "$lines_removed" ]; then
  added_int=$(printf '%.0f' "$lines_added")
  removed_int=$(printf '%.0f' "$lines_removed")
  if (( added_int != 0 || removed_int != 0 )); then
    line2_parts+=("$(printf "${GREEN}+%d${RESET}/${RED}-%d${RESET}" "$added_int" "$removed_int")")
  fi
fi

# --- output ---
line1=$(join_parts "${line1_parts[@]}")
line2=$(join_parts "${line2_parts[@]}")

if [ -n "$line2" ]; then
  printf "%b\n%b\n" "$line1" "$line2"
else
  printf "%b\n" "$line1"
fi
