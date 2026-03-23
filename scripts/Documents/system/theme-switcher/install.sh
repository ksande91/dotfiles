#!/bin/bash

# Function to check if the system is using pacman (Arch Linux or derivatives)
check_pacman() {
    if command -v pacman &> /dev/null; then
        echo "Using pacman as the package manager. Proceeding with installation..."
    else
        echo "Error: This script supports only Arch Linux or systems using pacman."
        echo "Please install the necessary dependencies manually."
        exit 1
    fi
}

# Function to install dependencies using pacman
install_dependencies() {
    echo "Installing dependencies with pacman..."
    sudo pacman -Sy --noconfirm rofi-wayland  python-pywal swww
}

# Make the script executable
make_script_executable() {
    chmod +x wallpaper-switcher.sh
}


# Main function to install and set up the environment
main() {
    check_pacman

    # Install the dependencies
    install_dependencies

    # Make the main script executable
    make_script_executable

    echo "Installation complete. You can now run ./wallpaper-switcher.sh to start."
}

# Execute the main function
main "$@"
