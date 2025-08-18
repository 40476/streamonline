#!/usr/bin/env bash

sloc="$HOME/.local/share/streamonline"
streamer_file="$sloc/openstreams_streamers-twitch.txt"
mkdir -p "$sloc"
touch "$streamer_file"
rm -f "$sloc/openstreams.txt"

streamonline_path="$(which streamonline.sh 2>/dev/null || echo "$HOME/.local/bin/streamonline.sh")"
openstreams_path="$(which openstreams.sh 2>/dev/null || echo "$HOME/.local/bin/openstreams.sh")"

function update_scripts() {
  echo "🔄 Updating scripts from GitHub..."
  curl -fsSL "https://raw.githubusercontent.com/40476/streamonline/main/streamonline.sh" -o "$streamonline_path" && chmod +x "$streamonline_path"
  curl -fsSL "https://raw.githubusercontent.com/40476/streamonline/main/openstreams.sh" -o "$openstreams_path" && chmod +x "$openstreams_path"
  echo "✅ Scripts updated successfully."
  exit 0
}

function load_streamers() {
  mapfile -t lines < "$streamer_file"
  default_quality="${lines[0]}"
  streamers=("${lines[@]:1}")
}

function dothething() {
  load_streamers
  quality="${1:-$default_quality}"
  count=0
  online_streamers=()
  > "$sloc/openstreams.txt"

  for i in "${streamers[@]}"; do
    (( count++ ))
    streamonline -c "$i" -s "https://twitch.tv/" >> "$sloc/openstreams.txt"
    current="$(sed "$count!d" "$sloc/openstreams.txt")"
    echo -e "$current"
    [[ "$current" == *"online"* ]] && online_streamers+=("$i")
  done

  echo "-----------------"
  if [ ${#online_streamers[@]} -eq 0 ]; then
    echo -e "\033[0;31m🚫 Nobody is online\033[0m"
  else
    grep online "$sloc/openstreams.txt"
    echo "-----------------"
    for i in "${online_streamers[@]}"; do
      echo "🎬 Launching $i with quality $quality..."
      streamlink --title "{author} - {category} - {title}" "https://twitch.tv/$i" "$quality"
    done
  fi
}

function add_streamer() {
  echo "➕ Enter Twitch handle to add:"
  read new_streamer
  if ! grep -qi "^$new_streamer\$" "$streamer_file"; then
    echo "$new_streamer" >> "$streamer_file"
    echo "✅ Added $new_streamer."
  else
    echo "⚠️ $new_streamer is already in the list."
  fi
}

function remove_streamer() {
  echo "➖ Enter Twitch handle to remove:"
  read remove_streamer
  if grep -qi "^$remove_streamer\$" "$streamer_file"; then
    grep -vi "^$remove_streamer\$" "$streamer_file" > "$streamer_file.tmp" && mv "$streamer_file.tmp" "$streamer_file"
    echo "✅ Removed $remove_streamer."
  else
    echo "⚠️ $remove_streamer not found in list."
  fi
}

function manual_stream() {
  echo "🎯 Enter Twitch handle:"
  read manuallyChosenStreamer
  streamlink "https://twitch.tv/$manuallyChosenStreamer" | grep "Available streams:"
  echo "🎚️ Enter desired quality:"
  read qlty
  streamlink --title "{author} - {category} - {title}" "https://twitch.tv/$manuallyChosenStreamer" "$qlty"
}

function clear_logs() {
  rm -f "$sloc/openstreams.txt" "$sloc/"*prog_state.txt
  echo "🧹 Logs cleared."
}

function menu() {
  echo -e "\n📺 Choose an option:"
  echo "(1) Automatic (timeout active)"
  echo "(2) Choose stream manually"
  echo "(3) Clear logs"
  echo "(4) Add streamer"
  echo "(5) Remove streamer"
  echo "(6) View current streamer list"
  echo "(7) Update scripts"
  echo ">>> "
  read -t 10 action

  case $action in
    1)
      echo "🎚️ Enter quality (or press Enter for default):"
      read -t 10 qlty
      dothething "${qlty:-$default_quality}"
      ;;
    2)
      manual_stream
      ;;
    3)
      clear_logs
      ;;
    4)
      add_streamer
      ;;
    5)
      remove_streamer
      ;;
    6)
      echo "📋 Current streamers:"
      cat "$streamer_file"
      printf "\n\nPress any key to exit."
      read
      ;;
    7)
      update_scripts
      ;;
    *)
      echo "⏱️ Timeout or invalid input. Proceeding automatically..."
      dothething "$default_quality"
      ;;
  esac
}

# 🧭 Entry point
if [[ "$1" == "--update" ]]; then
  update_scripts
fi

menu
