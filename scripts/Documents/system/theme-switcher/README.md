# Theme Switcher Script

This script allows you to switch your wallpaper and theme using pywal, rofi and swww.

## Prerequisites

The following dependencies are requried:
- [rofi](https://github.com/davatorium/rofi)
- [pywal](https://github.com/dylanaraps/pywal)
- [swww](https://github.com/Horus645/swww)
- `bash`, `find`, and standard Unix utilities.

## Installation

1. Clone this repository:

    ```bash
    git clone https://github.com/yourusername/wallpaper-switcher.git
    cd wallpaper-switcher
    ```

2. Run the install script to set up dependencies and make the script executable:

    ```bash
    ./install.sh
    ```

3. Run the script:

    ```bash
    ./wallpaper-switcher.sh /path/to/image/folder
    ```

## Configuration

- Customize the `rofi` theme in `config/theme-switcher.rasi`.

## License

This project is licensed under the MIT License.
