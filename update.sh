#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[*]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }

# Pull latest
info "Pulling latest changes..."
cd "$DOTFILES" && git pull origin main

# Always sync packages (--needed skips already installed)
info "Syncing packages..."
source "$DOTFILES/install.sh"
install_packages

# Stow all packages
info "Re-linking dotfiles..."
packages=(hypr waybar rofi dunst kitty wal shell scripts)
for pkg in "${packages[@]}"; do
    # Use --adopt then reset to handle conflicts with existing files/dirs
    stow -d "$DOTFILES" -t "$HOME" --adopt "$pkg" 2>/dev/null || true
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
hyprctl reload 2>/dev/null || warn "Hyprland not running"
killall waybar 2>/dev/null; waybar &>/dev/null &
killall dunst 2>/dev/null; dunst &>/dev/null &

# Regenerate pywal
if command -v wal &>/dev/null; then
    wal -R 2>/dev/null || warn "No previous pywal theme to restore"
fi

# Rebuild Go tools if present
if [ -d "$HOME/Documents/system/update-prompt" ]; then
    cd "$HOME/Documents/system/update-prompt"
    go build -o update_prompt update_prompt.go 2>/dev/null && info "  update-prompt rebuilt"
fi

warn "Shell/kitty changes will apply in new terminals"
warn "Rofi changes will apply next time you open it"

echo
info "Update complete!"
