# Dotfiles Installation for Hyprland

This project contains the necessary configuration files for setting up **Hyprland**, a Wayland compositor, with custom configurations for **Hyprland** and **Hyprlock**. The installation is automated through a simple bash script (`install.sh`), which will copy the configuration files from the repository to the appropriate locations in your home directory.

## Table of Contents

- [Installation](#installation)
- [Configuration Files](#configuration-files)
- [Directory Structure](#directory-structure)
- [Customization](#customization)
- [License](#license)

## Installation

1. Clone the repository to your local machine:

   ```bash
   git clone <repository-url> ~/.dotfiles
   ```

2. Navigate to the directory:

   ```bash
   cd ~/.dotfiles
   ```

3. Run the `install.sh` script to install the dotfiles:

   ```bash
   ./install.sh
   ```

   The script will:

   - Check if the necessary directories exist and create them if they don't.
   - Back up existing configuration files if they already exist.
   - Copy the custom configuration files for **Hyprland** and **Hyprlock** into the correct directories.

4. After the installation is complete, the configurations for Hyprland and Hyprlock will be applied.

## Configuration Files

The project includes the following configuration files:

- **Hyprland Configuration**: `~/.config/hypr/hyprland.conf`
- **Hyprlock Configuration**: `~/.config/hypr/hyprlock.conf`

These configuration files are placed in the respective directories inside `~/.config/hypr/` after running the installation script.

## Customization

You can easily modify the configuration files (`hyprland.conf` and `hyprlock.conf`) to tailor Hyprland's behavior to your needs. After you make changes to these files, you may need to restart Hyprland for the changes to take effect.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
