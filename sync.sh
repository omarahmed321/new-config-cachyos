#!/usr/bin/env bash
set -e

#===============================================================================
#   Dotfiles Sync Script for CachyOS (Wayland / Hyprland)
#   Collects live system configs, packages, keybindings, scripts, and themes
#===============================================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_NAME="$(whoami)"
HOME_DIR="$HOME"

echo "=== [1/6] Dynamic System Audit & Hyprland Check ==="

# 1. Check if Hyprland is installed, install via pacman if missing
if ! command -v hyprctl &>/dev/null && ! pacman -Qi hyprland &>/dev/null; then
    echo "⚠️ Hyprland is NOT installed! Installing Hyprland using pacman..."
    sudo pacman -S --noconfirm hyprland
else
    echo "✓ Hyprland is installed."
fi

# 2. Inspect active/installed nightlight tool
NIGHTLIGHT_TOOL="unknown"
if ps aux | grep -v grep | grep -q "hyprsunset"; then
    NIGHTLIGHT_TOOL="hyprsunset"
elif ps aux | grep -v grep | grep -q "wlsunset"; then
    NIGHTLIGHT_TOOL="wlsunset"
elif ps aux | grep -v grep | grep -q "gammastep"; then
    NIGHTLIGHT_TOOL="gammastep"
elif grep -rq "hyprsunset" "$HOME/.config/hypr/" 2>/dev/null; then
    NIGHTLIGHT_TOOL="hyprsunset"
elif grep -rq "wlsunset" "$HOME/.config/hypr/" 2>/dev/null; then
    NIGHTLIGHT_TOOL="wlsunset"
elif grep -rq "gammastep" "$HOME/.config/hypr/" 2>/dev/null; then
    NIGHTLIGHT_TOOL="gammastep"
fi
echo "✓ Detected Nightlight tool: $NIGHTLIGHT_TOOL"

# 3. Create destination folders in repo
mkdir -p "$REPO_DIR/packages"
mkdir -p "$REPO_DIR/configs"
mkdir -p "$REPO_DIR/dotfiles"
mkdir -p "$REPO_DIR/keybinds"
mkdir -p "$REPO_DIR/vscode"
mkdir -p "$REPO_DIR/wallpapers"
mkdir -p "$REPO_DIR/fonts"
mkdir -p "$REPO_DIR/services"
mkdir -p "$REPO_DIR/scripts"

echo "=== [2/6] Exporting Installed Packages ==="
if command -v pacman &>/dev/null; then
    pacman -Qqe > "$REPO_DIR/packages/pacman.txt"
    echo "✓ Saved $(wc -l < "$REPO_DIR/packages/pacman.txt") pacman packages."
fi

if command -v yay &>/dev/null; then
    yay -Qqm > "$REPO_DIR/packages/aur.txt" 2>/dev/null || true
elif command -v paru &>/dev/null; then
    paru -Qqm > "$REPO_DIR/packages/aur.txt" 2>/dev/null || true
else
    pacman -Qm > "$REPO_DIR/packages/aur.txt" 2>/dev/null || true
fi
echo "✓ Saved $(wc -l < "$REPO_DIR/packages/aur.txt" 2>/dev/null || echo 0) AUR packages."

echo "=== [3/6] Copying Configuration Files (.config) ==="
CONFIG_DIRS=(
    "hypr"
    "waybar"
    "rofi"
    "dunst"
    "kitty"
    "alacritty"
    "fastfetch"
    "fish"
    "btop"
    "yazi"
    "gtk-3.0"
    "gtk-4.0"
    "qt5ct"
    "qt6ct"
    "Kvantum"
    "nwg-look"
    "swappy"
    "wlogout"
    "cava"
    "lsd"
    "wal"
    "noctalia"
)

for cdir in "${CONFIG_DIRS[@]}"; do
    if [ -d "$HOME/.config/$cdir" ]; then
        rm -rf "$REPO_DIR/configs/$cdir"
        cp -rL "$HOME/.config/$cdir" "$REPO_DIR/configs/"
        echo "✓ Copied ~/.config/$cdir"
    fi
done

# Copy individual config files under ~/.config if present
for cfile in "mimeapps.list" "user-dirs.dirs" "antigravity-ide-flags.conf" "code-flags.conf" "spotify-flags.conf"; do
    if [ -f "$HOME/.config/$cfile" ]; then
        cp -L "$HOME/.config/$cfile" "$REPO_DIR/configs/"
    fi
done

echo "=== [4/6] Copying Dotfiles, Scripts, VSCode, Fonts, Services ==="

# Home dotfiles
for df in ".zshrc" ".bashrc" ".gitconfig" ".profile" ".xprofile"; do
    if [ -f "$HOME/$df" ]; then
        cp -L "$HOME/$df" "$REPO_DIR/dotfiles/"
        echo "✓ Copied ~/$df"
    fi
done

# Keybinds explicit backup
if [ -f "$HOME/.config/hypr/keybindings.conf" ]; then
    cp "$HOME/.config/hypr/keybindings.conf" "$REPO_DIR/keybinds/"
fi
if [ -f "$HOME/.config/hypr/hyprland.conf" ]; then
    cp "$HOME/.config/hypr/hyprland.conf" "$REPO_DIR/keybinds/"
fi

# Custom scripts (~/.local/share/bin and ~/.local/bin)
if [ -d "$HOME/.local/share/bin" ]; then
    cp -rL "$HOME/.local/share/bin/." "$REPO_DIR/scripts/"
    echo "✓ Copied scripts from ~/.local/share/bin"
fi
if [ -d "$HOME/.local/bin" ]; then
    for sfile in "$HOME/.local/bin"/*.sh; do
        if [ -f "$sfile" ]; then
            cp -L "$sfile" "$REPO_DIR/scripts/"
        fi
    done
fi

# VSCode settings & extensions
VSCODE_USER_DIR=""
if [ -d "$HOME/.config/Code/User" ]; then
    VSCODE_USER_DIR="$HOME/.config/Code/User"
elif [ -d "$HOME/.config/Code - OSS/User" ]; then
    VSCODE_USER_DIR="$HOME/.config/Code - OSS/User"
fi

if [ -n "$VSCODE_USER_DIR" ]; then
    [ -f "$VSCODE_USER_DIR/settings.json" ] && cp "$VSCODE_USER_DIR/settings.json" "$REPO_DIR/vscode/"
    [ -f "$VSCODE_USER_DIR/keybindings.json" ] && cp "$VSCODE_USER_DIR/keybindings.json" "$REPO_DIR/vscode/"
    echo "✓ Copied VSCode settings and keybindings."
fi

if command -v code &>/dev/null; then
    code --list-extensions > "$REPO_DIR/vscode/extensions.txt" 2>/dev/null || true
elif command -v code-oss &>/dev/null; then
    code-oss --list-extensions > "$REPO_DIR/vscode/extensions.txt" 2>/dev/null || true
fi
echo "✓ Saved VSCode extensions list."

# Systemd user services
if command -v systemctl &>/dev/null; then
    systemctl --user list-unit-files --state=enabled | awk '{print $1}' | grep '\.service$' > "$REPO_DIR/services/user_services.txt" || true
    echo "✓ Saved enabled systemd user services."
fi

# User Fonts
if [ -d "$HOME/.local/share/fonts" ]; then
    cp -rL "$HOME/.local/share/fonts/." "$REPO_DIR/fonts/" 2>/dev/null || true
    echo "✓ Copied user fonts."
fi

# Wallpapers
if [ -d "$HOME/.config/hypr/themes" ]; then
    cp -rL "$HOME/.config/hypr/themes/." "$REPO_DIR/wallpapers/" 2>/dev/null || true
    echo "✓ Copied theme wallpapers."
fi

echo "=== [5/6] Sanitizing Hardcoded Absolute Paths (/home/$USER_NAME -> \$HOME) ==="

# Find and replace hardcoded home path in repo text files
find "$REPO_DIR/configs" "$REPO_DIR/scripts" "$REPO_DIR/keybinds" "$REPO_DIR/dotfiles" -type f \( -name "*.conf" -o -name "*.json" -o -name "*.jsonc" -o -name "*.sh" -o -name "*.py" -o -name "*.ini" \) 2>/dev/null | while read -r file; do
    if grep -q "/home/$USER_NAME" "$file"; then
        sed -i "s|/home/$USER_NAME|\$HOME|g" "$file"
        echo "  - Sanitized path in $(basename "$file")"
    fi
done

echo "=== [6/6] Sync Completed Successfully! ==="
echo "All configs, keybindings, scripts, packages, and dotfiles are synced in repo."
