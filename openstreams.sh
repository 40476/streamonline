#!/usr/bin/env bash

for cmd in curl streamlink; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "❌ $cmd is not installed. Please install it and try again."
    exit 1
  fi
done

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
  printf "streamonline.sh saved as %s\n" "$streamonline_path"
  curl -fsSL "https://raw.githubusercontent.com/40476/streamonline/main/openstreams.sh" -o "$openstreams_path" && chmod +x "$openstreams_path"
  printf "openstreams.sh saved as %s\n" "$openstreams_path"
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
  true > "$sloc/openstreams.txt" # Use 'true' as a no-op for redirection
  online_streamers=()

  for entry in "${streamer_entries[@]}"; do
    url="${entry%%|*}"
    quality="${entry#*|}"
    [[ "$quality" == "$url" ]] && quality="$default_quality"

    name="$(basename "$url")"
    # echo $streamonline_path -c "$name" -s "${url%/*}/"
    "$streamonline_path" -c "$name" -s "${url%/*}/" >> "$sloc/openstreams.txt"
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
  echo "🔗 Paste full stream URL (or press Enter to cancel):"
  read -r url
  [[ -z "$url" ]] && echo "❌ No URL provided. Canceling." && return
  echo "🎚️ Enter preferred quality (or press Enter for default: $default_quality):"
  read -r quality
  quality="${quality:-$default_quality}"
  if ! grep -q "^$url|" "$streamer_file"; then
    if [[ "$quality" == "$default_quality" ]]; then
      echo -e "\n$url" >> "$streamer_file"
    else
      echo -e "\n$url|$quality" >> "$streamer_file"
    fi
    echo "✅ Added $url with quality $quality."
  else
    echo "⚠️ $url is already in the list."
  fi
}

function remove_streamer() {
  echo "🔗 Paste full stream URL to remove (or press Enter to cancel):"
  read -r url
  [[ -z "$url" ]] && echo "❌ No URL provided. Canceling." && return
  if grep -q "^$url|" "$streamer_file"; then
    grep -v "^$url|" "$streamer_file" > "$streamer_file.tmp" && mv "$streamer_file.tmp" "$streamer_file"
    echo "✅ Removed $url."
  else
    echo "⚠️ $url not found in list."
  fi
}

function manual_stream() {
  echo "🔗 Paste full stream URL (or press Enter to cancel):"
  read -r url
  [[ -z "$url" ]] && echo "❌ No URL provided. Canceling." && return
  streamlink "$url" | grep "Available streams:"
  echo "🎚️ Enter desired quality (or press Enter for default: $default_quality):"
  read -r qlty
  qlty="${qlty:-$default_quality}"
  streamlink --title "{author} - {category} - {title}" "$url" "$qlty"
}

function clear_logs() {
  rm -f "$sloc/openstreams.txt" "$sloc/"*prog_state.txt
  echo "🧹 Logs cleared."
}

function manage_streamers() {
  load_streamers
  local selected=0
  local action=""

  while true; do
    clear
    echo "🎛️ Manage Streamers:"
    echo "Use Up/Down arrow keys to scroll, 'a' to add, 'r' to remove, 'e' to edit, and 'q' to quit."

    # Display the streamer list with the selected item highlighted
    for i in "${!streamer_entries[@]}"; do
      if [[ $i -eq $selected ]]; then
        echo -e "  \033[1;32m> ${streamer_entries[$i]}\033[0m"
      else
        echo "    ${streamer_entries[$i]}"
      fi
    done

    # Read user input
    read -rsn1 input
    case $input in
      $'\x1b') # Detect arrow keys (escape sequence)
        read -rsn2 -t 0.1 input
        case $input in
          "[A") # Up arrow
            ((selected--))
            if [[ $selected -lt 0 ]]; then
              selected=$((${#streamer_entries[@]} - 1))
            fi
            ;;
          "[B") # Down arrow
            ((selected++))
            if [[ $selected -ge ${#streamer_entries[@]} ]]; then
              selected=0
            fi
            ;;
        esac
        ;;
      # Add a new streamer
      a)
        add_streamer
        load_streamers # Reload the streamer list after adding
        ;;
      # Remove the selected streamer
      r)
        if [[ -n "${streamer_entries[$selected]}" ]]; then
          local url_to_remove="${streamer_entries[$selected]%%|*}"
          grep -v "^$url_to_remove" "$streamer_file" > "$streamer_file.tmp" && mv "$streamer_file.tmp" "$streamer_file"
          echo "✅ Removed $url_to_remove."
          sleep 1
          load_streamers # Reload the streamer list after removing
          selected=0
        fi
        ;;
      # Edit the selected streamer
      e)
        if [[ -n "${streamer_entries[$selected]}" ]]; then
          local url_to_edit="${streamer_entries[$selected]%%|*}"
          local current_quality="${streamer_entries[$selected]#*|}"
          [[ "$current_quality" == "$url_to_edit" ]] && current_quality="$default_quality"

          echo "🔗 Current URL: $url_to_edit"
          echo "🎚️ Current quality: $current_quality"
          echo "Enter new URL (or press Enter to keep current):"
          read -r new_url
          new_url="${new_url:-$url_to_edit}"
          echo "Enter new quality (or press Enter to keep current: $current_quality):"
          read -r new_quality
          new_quality="${new_quality:-$current_quality}"

          # Update the streamer entry
          grep -v "^$url_to_edit" "$streamer_file" > "$streamer_file.tmp"
          echo "$new_url|$new_quality" >> "$streamer_file.tmp"
          mv "$streamer_file.tmp" "$streamer_file"
          echo "✅ Updated $url_to_edit."
          sleep 1
          load_streamers # Reload the streamer list after editing
        fi
        ;;
      # Quit the manage streamers menu
      q)
        return
        ;;
    esac
  done
}

function menu() {
  echo -e "\n📺 Choose an option:"
  echo "(1) Automatic (timeout active)"
  echo "(2) Choose stream manually"
  echo "(3) Clear logs"
  echo "(4) Manage streamers"
  echo "(5) Update or install scripts"
  echo "(6) Exit"
  echo -n ">>> "
  read -r -t 10 action
  action="${action:-1}" # Default to option 1 if no input

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
      manage_streamers
      ;;
    5)
      update_scripts
      ;;
    6)
      echo "👋 Exiting."
      exit 0
      ;;
    *)
      echo "⏱️ Timeout or invalid input. Proceeding automatically..."
      dothething
      ;;
  esac
}

# 🧭 Entry point also run when --install and when --update
if [[ "$1" == "--update" || "$2" == "--install" ]]; then
  update_scripts
fi

menu
