# Dotfiles — Hyprland Desktop

Arch Linux + Hyprland desktop environment managed with [GNU Stow](https://www.gnu.org/software/stow/). Dynamic theming via pywal, AI-powered wallpaper generation, and modular config layout.

## Quick Start

```bash
# On a fresh Arch install
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

The bootstrap script handles everything: system packages, AUR helper (yay), pyenv, nvm, dotfile symlinks, Go tool builds, and initial pywal theme setup.

You can also run individual steps:

```bash
./install.sh link_dotfiles
./install.sh setup_python
./install.sh build_go_tools
```

## Stow Packages

Each directory is a GNU Stow package that symlinks into `$HOME`:

| Package | Target | Contents |
|---------|--------|----------|
| `hypr/` | `~/.config/hypr/` | Hyprland + hyprlock config (modular split) |
| `waybar/` | `~/.config/waybar/` | Bar config, pywal-themed style, modules |
| `rofi/` | `~/.config/rofi/` | Application launcher config |
| `dunst/` | `~/.config/dunst/` | Notification daemon config |
| `kitty/` | `~/.config/kitty/` | Terminal emulator + DesertNight theme |
| `wal/` | `~/.config/wal/templates/` | Pywal templates for Hyprland + Waybar colors |
| `shell/` | `~/` | `.bashrc`, `.bash_profile` |
| `scripts/` | `~/Documents/system/` | Theme-switcher, update-prompt |

## Theming

Colors are generated dynamically from the current wallpaper using **pywal**:

1. Pick a wallpaper via `Super+T` (rofi image picker) or `Super+W` (wallpaper-ai)
2. Pywal extracts a color palette and writes it to `~/.cache/wal/`
3. Templates in `wal/.config/wal/templates/` generate:
   - `colors-hyprland.conf` — border colors (`$color0`–`$color15`)
   - `colors-waybar.css` — `@define-color` variables for the bar
4. Hyprland and Waybar both source these generated files

## Key Bindings

| Bind | Action |
|------|--------|
| `Super+Q` | Terminal (kitty) |
| `Super+R` | App launcher (rofi) |
| `Super+B` | Browser (firefox) |
| `Super+E` | File manager |
| `Super+T` | Theme switcher (rofi wallpaper picker) |
| `Super+W` | wallpaper-ai (AI wallpaper generator) |
| `Super+Shift+W` | Random AI wallpaper from learned preferences |
| `Super+F1–F5` | Rate current wallpaper (1–5) |
| `Super+L` | Lock screen (hyprlock) |
| `Super+Shift+P` | Screenshot (grim + slurp) |
| `Super+1–0` | Switch workspace |
| `Alt+R` | Enter resize mode (arrows to resize, Esc to exit) |

## Custom Tools

### theme-switcher
Bash script that uses rofi to browse wallpapers with thumbnails, applies the selection via pywal + swww, and updates hyprlock.

### update-prompt
Go TUI (Bubble Tea) that prompts for system updates (`yay -Syu`) on login. Launched automatically on startup in a floating kitty window.

### wallpaper-ai
Separate Python project ([repo](~/Documents/personal/wallpaper-ai)) — generates wallpapers with AI, learns preferences from ratings. Requires `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, and `FAL_KEY`.

## Post-Install

1. **API keys** — copy the example and fill in your keys:
   ```bash
   cp ~/dotfiles/shell/.bashrc_secrets.example ~/.bashrc_secrets
   ```
2. **Monitors** — edit for your hardware:
   ```bash
   vim ~/.config/hypr/conf/monitors.conf
   # Use 'hyprctl monitors' to see detected outputs
   ```
3. **Wallpapers** — add images to `~/Pictures/wallpaper/`, then pick one with `Super+T`

## License

MIT — see [LICENSE](LICENSE).
