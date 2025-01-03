#!/bin/bash

# Directories and files
DOTFILES_DIR="$HOME/dotfiles"
HYPRLAND_CONFIG_REPO="$DOTFILES_DIR/.config/hypr/hyprland.conf"
HYPRLAND_CONFIG_DEST="$HOME/.config/hypr/hyprland.conf"
HYPRLOCK_CONFIG_REPO="$DOTFILES_DIR/.config/hypr/hyprlock.conf"
HYPRLOCK_CONFIG_DEST="$HOME/.config/hypr/hyprlock.conf"
CONFIG_FOLDER_REPO="$DOTFILES_DIR/.config/hypr/conf"
CONFIG_FOLDER_DEST="$HOME/.config/hypr/conf"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting dotfiles installation...${NC}"

# Ensure the destination directory exists
if [ ! -d "$HOME/.config/hypr" ]; then
    echo -e "${YELLOW}Creating Hyprland config directory...${NC}"
    mkdir -p "$HOME/.config/hypr"
fi

# Back up existing Hyprland configurations
if [ -f "$HYPRLAND_CONFIG_DEST" ]; then
    echo -e "${YELLOW}Backing up existing Hyprland configuration...${NC}"
    mv "$HYPRLAND_CONFIG_DEST" "${HYPRLAND_CONFIG_DEST}.bak"
fi

if [ -f "$HYPRLOCK_CONFIG_DEST" ]; then
    echo -e "${YELLOW}Backing up existing Hyprlock configuration...${NC}"
    mv "$HYPRLOCK_CONFIG_DEST" "${HYPRLOCK_CONFIG_DEST}.bak"
fi

# Back up existing config folder if it exists
if [ -d "$CONFIG_FOLDER_DEST" ]; then
    echo -e "${YELLOW}Backing up existing config folder...${NC}"
    mv "$CONFIG_FOLDER_DEST" "${CONFIG_FOLDER_DEST}.bak"
fi

# Copy the Hyprland configuration files
echo -e "${GREEN}Copying Hyprland configuration files...${NC}"
cp "$HYPRLAND_CONFIG_REPO" "$HYPRLAND_CONFIG_DEST"
cp "$HYPRLOCK_CONFIG_REPO" "$HYPRLOCK_CONFIG_DEST"

# Copy the config folder
echo -e "${GREEN}Copying config folder...${NC}"
cp -r "$CONFIG_FOLDER_REPO" "$CONFIG_FOLDER_DEST"

echo -e "${GREEN}Dotfiles installation complete.${NC}"

