#!/usr/bin/env bash

sloc="$HOME/.local/share/streamonline"
streamer_file="$sloc/openstreams_streamers.txt"
mkdir -p "$sloc"
touch "$streamer_file"
rm -f "$sloc/openstreams.txt"

streamonline_path="$(which streamonline.sh 2>/dev/null || which streamonline 2>/dev/null || echo "$HOME/.local/bin/streamonline.sh")"
openstreams_path="$(which openstreams.sh 2>/dev/null || which openstreams 2>/dev/null || echo "$HOME/.local/bin/openstreams.sh")"

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
  streamer_entries=("${lines[@]:1}")
}

function dothething() {
  load_streamers
  > "$sloc/openstreams.txt"
  online_streamers=()

  for entry in "${streamer_entries[@]}"; do
    url="${entry%%|*}"
    quality="${entry#*|}"
    [[ "$quality" == "$url" ]] && quality="$default_quality"

    name="$(basename "$url")"
    # echo $streamonline_path -c "$name" -s "${url%/*}/"
    $streamonline_path -c "$name" -s "${url%/*}/" >> "$sloc/openstreams.txt"
    current="$(tail -n 1 "$sloc/openstreams.txt")"
    echo -e "$current"
    [[ "$current" == *"online"* ]] && online_streamers+=("$url|$quality")
  done

  echo "-----------------"
  if [ ${#online_streamers[@]} -eq 0 ]; then
    echo -e "\033[0;31m🚫 Nobody is online\033[0m"
  else
    grep online "$sloc/openstreams.txt"
    echo "-----------------"
    for entry in "${online_streamers[@]}"; do
      url="${entry%%|*}"
      quality="${entry#*|}"
      echo "🎬 Launching $url with quality $quality..."
      streamlink --title "{author} - {category} - {title}" "$url" "$quality"
    done
  fi
}

function add_streamer() {
  echo "🔗 Paste full stream URL:"
  read url
  echo "🎚️ Enter preferred quality (or leave blank for default):"
  read quality
  quality="${quality:-$default_quality}"

  if ! grep -q "^$url|" "$streamer_file"; then
    echo "$url|$quality" >> "$streamer_file"
    echo "✅ Added $url with quality $quality."
  else
    echo "⚠️ $url is already in the list."
  fi
}

function remove_streamer() {
  echo "🔗 Paste full stream URL to remove:"
  read url
  if grep -q "^$url|" "$streamer_file"; then
    grep -v "^$url|" "$streamer_file" > "$streamer_file.tmp" && mv "$streamer_file.tmp" "$streamer_file"
    echo "✅ Removed $url."
  else
    echo "⚠️ $url not found in list."
  fi
}

function manual_stream() {
  echo "🔗 Paste full stream URL:"
  read url
  streamlink "$url" | grep "Available streams:"
  echo "🎚️ Enter desired quality:"
  read qlty
  streamlink --title "{author} - {category} - {title}" "$url" "$qlty"
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
      dothething
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
      dothething
      ;;
  esac
}

# 🧭 Entry point
if [[ "$1" == "--update" ]]; then
  update_scripts
fi

menu
