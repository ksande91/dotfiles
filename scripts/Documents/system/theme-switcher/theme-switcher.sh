#!/bin/bash

# Dependency checks
command -v rofi >/dev/null 2>&1 || { echo "Error: rofi is not installed." >&2; exit 1; }
command -v wal >/dev/null 2>&1 || { echo "Error: pywal is not installed." >&2; exit 1; }
command -v awww >/dev/null 2>&1 || { echo "Error: awww is not installed." >&2; exit 1; }

# Check if an argument (path to image directory) is provided
if [ -z "$1" ]; then
    echo "Error: Missing argument. Please provide the path to the image directory."
    exit 1
fi

# Set the image directory to the provided argument
IMAGE_DIR="$1"

# Check if IMAGE_DIR exists
if [ ! -d "$IMAGE_DIR" ]; then
    echo "Error: Image directory $IMAGE_DIR does not exist."
    exit 1
fi

# Use find to get all image files in the directory
images=($(find "$IMAGE_DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \)))

# Check if images are found
if [ ${#images[@]} -eq 0 ]; then
  notify-send "No images found in $IMAGE_DIR"
  exit 1
fi

# Generate rofi options dynamically
options=""
for image in "${images[@]}"; do
  # Extract filename without path and extension for display
  name=$(basename "${image}" | sed 's/\.[^.]*$//')
  options+=${name}"\0icon\x1f${image}\n"
done

# Display options using rofi
selected=$(echo -e "$options" | rofi -dmenu -show-icons -theme "$(dirname "$(realpath "$0")")/config/config.rasi" -lines "${#images[@]}")

# Exit if nothing is selected
if [ -z "$selected" ]; then
    exit 0
fi

# Find the full path of the selected image
for image in "${images[@]}"; do
  if [[ $(basename "$image" | sed 's/\.[^.]*$//') == "$selected" ]]; then
    selected_image="$image"
    break
  fi
done

# Apply the wallpaper using wal and awww
if [ -n "$selected_image" ]; then
  wal -n -i "$selected_image"
  awww img "$(< "${HOME}/.cache/wal/wal")"

  # Get the path from wal cache (where the final wallpaper path is stored)
  wallpaper_path="$(< "${HOME}/.cache/wal/wal")"

  # Check if the wallpaper path exists (just in case)
  if [ -f "$wallpaper_path" ]; then
    # Update Hyprlock background configuration
    hyprlock_conf="$HOME/.config/hypr/hyprlock.conf"

    # Ensure Hyprlock config exists
    if [ ! -f "$hyprlock_conf" ]; then
      echo "Error: Hyprlock config file not found."
      exit 1
    fi

    # Check if the background block exists
    if grep -q "^background {" "$hyprlock_conf"; then
      # Add the new path inside the existing background block
      sed -i "/^background {/,/^}/ s|^}|    path = $wallpaper_path\n}|" "$hyprlock_conf"
    else
      # If the background block doesn't exist, create it
      echo -e "\nbackground {\n    monitor = \n    path = $wallpaper_path\n}" >> "$hyprlock_conf"
    fi

    # Optionally, reload or restart Hyprlock if needed (uncomment the next line if applicable)
    # pkill -HUP hyprlock

    echo "Hyprlock background updated to: $wallpaper_path"
  else
    notify-send "Error: Wallpaper file not found at $wallpaper_path"
  fi
else
  notify-send "Error: Image not found!"
  exit 1
fi
