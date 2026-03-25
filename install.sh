#!/bin/bash

# =============================================================================
# Dotfiles Bootstrap Script
# Installs packages, links configs, and builds tools for a Hyprland desktop
# =============================================================================

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[*]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }

# -----------------------------------------------------------------------------
# 1. System packages
# -----------------------------------------------------------------------------
install_packages() {
    info "Installing system packages..."
    sudo pacman -Syu --noconfirm || true

    # Read package list, ignoring comments and blank lines
    local pkgs
    pkgs=$(grep -v '^#\|^$' "$DOTFILES/packages.txt")
    if command -v yay &>/dev/null; then
        yay -S --needed --noconfirm $pkgs
    else
        sudo pacman -S --needed --noconfirm $pkgs
    fi

    # Enable audio services
    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
    # Enable network and bluetooth
    sudo systemctl enable --now NetworkManager 2>/dev/null || true
    sudo systemctl enable --now bluetooth 2>/dev/null || true
}

# -----------------------------------------------------------------------------
# 2. AUR helper (yay)
# -----------------------------------------------------------------------------
install_yay() {
    if command -v yay &>/dev/null; then
        info "yay already installed"
        return
    fi
    info "Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay-install
    cd /tmp/yay-install && makepkg -si --noconfirm
    cd "$DOTFILES"
    rm -rf /tmp/yay-install
}

# -----------------------------------------------------------------------------
# 3. AUR packages
# -----------------------------------------------------------------------------
install_aur_packages() {
    info "Installing AUR packages..."
    yay -S --needed --noconfirm \
        swww \
        wlogout
}

# -----------------------------------------------------------------------------
# 4. Python (pyenv)
# -----------------------------------------------------------------------------
setup_python() {
    info "Setting up Python via pyenv..."
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"

    if ! pyenv versions --bare | grep -q "3.12"; then
        pyenv install 3.12
    fi
    pyenv global 3.12
    info "Python $(python --version) ready"
}

# -----------------------------------------------------------------------------
# 5. Node.js (nvm)
# -----------------------------------------------------------------------------
setup_node() {
    if [ -d "$HOME/.nvm" ]; then
        info "nvm already installed"
        return
    fi
    info "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
}

# -----------------------------------------------------------------------------
# 6. Stow dotfiles
# -----------------------------------------------------------------------------
link_dotfiles() {
    info "Linking dotfiles with GNU Stow..."

    local packages=(hypr waybar rofi dunst kitty wal shell scripts)
    for pkg in "${packages[@]}"; do
        info "  Stowing $pkg..."
        # Remove conflicting default files, then stow
        stow -d "$DOTFILES" -t "$HOME" --adopt "$pkg" 2>/dev/null
        # Reset any adopted files back to repo version
        git -C "$DOTFILES" checkout -- "$pkg" 2>/dev/null
    done

    info "Dotfiles linked"
}

# -----------------------------------------------------------------------------
# 7. Build Go tools
# -----------------------------------------------------------------------------
build_go_tools() {
    info "Building Go tools..."

    if [ -d "$HOME/Documents/system/update-prompt" ]; then
        cd "$HOME/Documents/system/update-prompt"
        go build -o update_prompt update_prompt.go
        info "  update-prompt built"
    fi

    cd "$DOTFILES"
}

# -----------------------------------------------------------------------------
# 8. Install wallpaper-ai (if repo is present)
# -----------------------------------------------------------------------------
setup_wallpaper_ai() {
    local repo="$HOME/Documents/personal/wallpaper-ai"
    if [ -d "$repo" ]; then
        info "Installing wallpaper-ai..."
        pip install -e "$repo"
    else
        warn "wallpaper-ai repo not found at $repo — clone it manually if needed"
    fi
}

# -----------------------------------------------------------------------------
# 9. Secrets
# -----------------------------------------------------------------------------
setup_secrets() {
    if [ ! -f "$HOME/.bashrc_secrets" ]; then
        warn "No ~/.bashrc_secrets found"
        warn "Copy the example and fill in your API keys:"
        warn "  cp $DOTFILES/shell/.bashrc_secrets.example ~/.bashrc_secrets"
    else
        info "~/.bashrc_secrets already exists"
    fi
}

# -----------------------------------------------------------------------------
# 10. Machine-specific: monitors
# -----------------------------------------------------------------------------
setup_monitors() {
    local monitors_conf="$HOME/.config/hypr/conf/monitors.conf"
    warn "Current monitors.conf:"
    cat "$monitors_conf"
    echo
    warn "Edit ~/.config/hypr/conf/monitors.conf if this doesn't match your new hardware"
    warn "Use 'hyprctl monitors' after booting Hyprland to see detected outputs"
}

# -----------------------------------------------------------------------------
# 11. Initial theme
# -----------------------------------------------------------------------------
setup_initial_theme() {
    info "Setting up initial pywal theme..."
    mkdir -p "$HOME/Pictures/wallpaper"

    local first_wallpaper
    first_wallpaper=$(find "$HOME/Pictures/wallpaper" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | head -1)

    if [ -n "$first_wallpaper" ]; then
        wal -i "$first_wallpaper"
        info "Theme generated from: $first_wallpaper"
    else
        # Generate a default theme so Hyprland can start without color errors
        wal --theme dark-decay
        info "No wallpapers found — applied default dark theme"
        warn "Add images to ~/Pictures/wallpaper/ and run: wal -i <image>"
    fi
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "==========================================="
    echo "  Dotfiles Bootstrap Installer"
    echo "==========================================="
    echo
    echo "This will install and configure:"
    echo "  - System packages (hyprland, waybar, dunst, rofi, kitty, etc.)"
    echo "  - AUR helper (yay)"
    echo "  - Python (pyenv 3.12), Node.js (nvm)"
    echo "  - Symlink all dotfiles via GNU Stow"
    echo "  - Build Go tools (update-prompt)"
    echo "  - Set up pywal theme"
    echo
    read -rp "Continue? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 0

    install_packages
    install_yay
    install_aur_packages
    setup_python
    setup_node
    link_dotfiles
    build_go_tools
    setup_wallpaper_ai
    setup_secrets
    setup_monitors
    setup_initial_theme

    echo
    info "========================================="
    info "  Bootstrap complete!"
    info "========================================="
    info ""
    info "Next steps:"
    info "  1. Set up API keys:  cp $DOTFILES/shell/.bashrc_secrets.example ~/.bashrc_secrets"
    info "  2. Edit monitors:    vim ~/.config/hypr/conf/monitors.conf"
    info "  3. Add wallpapers:   cp <images> ~/Pictures/wallpaper/"
    info "  4. Start Hyprland:   Hyprland"
}

# Only run when executed directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ -n "$1" ]; then
        "$1"
    else
        main
    fi
fi
