#!/bin/bash

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
LOGFILE="$DOTFILES/update.log"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[*]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }

# Log everything to file and terminal
exec > >(tee -a "$LOGFILE") 2>&1
echo ""
echo "=== Update started: $(date) ==="

# Pull latest
info "Pulling latest changes..."
cd "$DOTFILES" && git pull origin main || { error "Git pull failed"; exit 1; }

# Always sync packages (--needed skips already installed)
info "Syncing packages..."
source "$DOTFILES/install.sh"
install_packages || { error "Package install failed — check $LOGFILE"; }

# Stow all packages
info "Re-linking dotfiles..."
packages=(hypr waybar rofi dunst kitty wal tmux shell scripts)
for pkg in "${packages[@]}"; do
    stow -d "$DOTFILES" -t "$HOME" --adopt "$pkg" 2>&1 || true
    git -C "$DOTFILES" checkout -- "$pkg" 2>/dev/null || true
    info "  Stowed $pkg"
done

# Manually link files in directories stow can't merge into
if [ -d "$DOTFILES/shell/.local/share/applications" ]; then
    mkdir -p "$HOME/.local/share/applications"
    for f in "$DOTFILES/shell/.local/share/applications"/*; do
        target="$HOME/.local/share/applications/$(basename "$f")"
        [ -L "$target" ] || ln -sf "$f" "$target"
    done
    info "  Linked desktop entries"
fi

# Reload services
info "Reloading services..."
hyprctl reload 2>&1 || warn "Hyprland not running"
killall waybar 2>/dev/null; setsid waybar &>/dev/null &
killall dunst 2>/dev/null; setsid dunst &>/dev/null &

# Regenerate pywal
if command -v wal &>/dev/null; then
    wal -R 2>&1 || warn "No previous pywal theme to restore"
fi

# Rebuild Go tools if present
if [ -d "$HOME/Documents/system/update-prompt" ]; then
    cd "$HOME/Documents/system/update-prompt"
    go build -o update_prompt update_prompt.go 2>&1 && info "  update-prompt rebuilt"
fi

warn "Shell/kitty changes will apply in new terminals"
warn "Rofi changes will apply next time you open it"

echo ""
info "Update complete! Full log: $LOGFILE"
