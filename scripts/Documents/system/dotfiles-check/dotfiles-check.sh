#!/bin/bash
# Periodically check for dotfiles repo changes and notify

DOTFILES="$HOME/dotfiles"
INTERVAL=300 # Check every 5 minutes

while true; do
    sleep "$INTERVAL"

    cd "$DOTFILES" || continue

    # Fetch silently
    git fetch origin main 2>/dev/null || continue

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
done
