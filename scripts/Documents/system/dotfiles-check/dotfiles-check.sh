#!/bin/bash
# Check for dotfiles updates on startup

DOTFILES="$HOME/dotfiles"

cd "$DOTFILES" || exit 1

# Fetch silently
git fetch origin main 2>/dev/null || exit 1

# Compare local and remote
LOCAL=$(git rev-parse HEAD 2>/dev/null)
REMOTE=$(git rev-parse origin/main 2>/dev/null)

if [ "$LOCAL" != "$REMOTE" ]; then
    CHANGES=$(git log --oneline HEAD..origin/main 2>/dev/null | head -5)
    notify-send -u critical "Dotfiles Update Available" "$CHANGES" \
        --action="update=Update Now"

    # If user clicks "Update Now"
    if [ $? -eq 0 ]; then
        kitty --class Floating -e bash -c "$DOTFILES/update.sh; echo 'Press Enter to close'; read"
    fi
fi
