#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[*]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }

# Get list of changed files before pulling
changed_files=$(cd "$DOTFILES" && git fetch origin main 2>/dev/null && git diff --name-only HEAD origin/main 2>/dev/null || echo "")

# Pull latest
info "Pulling latest changes..."
cd "$DOTFILES" && git pull origin main

if [ -z "$changed_files" ]; then
    info "Already up to date"
    exit 0
fi

echo "$changed_files" | sed 's/^/  /'

# Always sync packages (--needed skips already installed)
info "Syncing packages..."
source "$DOTFILES/install.sh"
install_packages

# Re-stow everything
info "Re-linking dotfiles..."
packages=(hypr waybar rofi dunst kitty wal shell scripts)
for pkg in "${packages[@]}"; do
    stow -d "$DOTFILES" -t "$HOME" --restow "$pkg" 2>/dev/null && \
        info "  Stowed $pkg"
done

# Reload services based on what changed
if echo "$changed_files" | grep -q "^hypr/"; then
    info "Reloading Hyprland..."
    hyprctl reload 2>/dev/null || warn "Hyprland not running"
fi

if echo "$changed_files" | grep -q "^waybar/"; then
    info "Restarting Waybar..."
    killall waybar 2>/dev/null; waybar &>/dev/null &
fi

if echo "$changed_files" | grep -q "^dunst/"; then
    info "Restarting Dunst..."
    killall dunst 2>/dev/null; dunst &>/dev/null &
fi

if echo "$changed_files" | grep -q "^wal/"; then
    info "Regenerating pywal colors..."
    if command -v wal &>/dev/null; then
        wal -R 2>/dev/null || warn "No previous pywal theme to restore"
    fi
fi

if echo "$changed_files" | grep -q "^scripts/.*\.go$"; then
    info "Rebuilding Go tools..."
    if [ -d "$HOME/Documents/system/update-prompt" ]; then
        cd "$HOME/Documents/system/update-prompt"
        go build -o update_prompt update_prompt.go 2>/dev/null && info "  update-prompt built"
    fi
fi

# These only take effect in new terminals
if echo "$changed_files" | grep -q "^shell/\|^kitty/"; then
    warn "Shell/kitty changes will apply in new terminals"
fi

if echo "$changed_files" | grep -q "^rofi/"; then
    warn "Rofi changes will apply next time you open it"
fi

echo
info "Update complete!"
