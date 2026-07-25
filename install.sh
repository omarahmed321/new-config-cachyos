#!/usr/bin/env bash

#===============================================================================
#   Personal Dotfiles Installer for CachyOS / Arch Wayland (Hyprland)
#===============================================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
BACKUP_DATE="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$HOME/.dotfiles_backup/$BACKUP_DATE"
FAILED_STEPS=()
SUCCESS_STEPS=()

# Auto-clone repository if running standalone via curl without local repo files
if [ ! -f "$REPO_DIR/packages/pacman.txt" ]; then
    DOTFILES_DIR="$HOME/cachyos-dotfiles"
    echo "📥 Downloading dotfiles repository into $DOTFILES_DIR..."
    if [ -d "$DOTFILES_DIR" ]; then
        (cd "$DOTFILES_DIR" && git pull 2>/dev/null || true)
    else
        if command -v git &>/dev/null; then
            git clone https://github.com/omarahmed321/new-config-cachyos.git "$DOTFILES_DIR"
        else
            sudo pacman -S --needed --noconfirm git
            git clone https://github.com/omarahmed321/new-config-cachyos.git "$DOTFILES_DIR"
        fi
    fi
    REPO_DIR="$DOTFILES_DIR"
    cd "$REPO_DIR" || exit 1
fi

# Parse CLI Flags
MODE="interactive"
INSTALL_CONFIGS=true
INSTALL_PACKAGES=true
INSTALL_THEMES=true
INSTALL_SCRIPTS=true
INSTALL_VSCODE=true
INSTALL_SERVICES=true

for arg in "$@"; do
    case $arg in
        --all|--non-interactive|-y)
            MODE="all"
            ;;
        --no-packages)
            INSTALL_PACKAGES=false
            ;;
        --no-vscode)
            INSTALL_VSCODE=false
            ;;
    esac
done

echo "================================================================="
echo "   🚀 Starting CachyOS Dotfiles Setup & Restoration"
echo "================================================================="

#-------------------------------------------------------------------------------
# 1. Pre-flight Checks
#-------------------------------------------------------------------------------
echo -e "\n🔍 [Check 1/13] Checking Operating System..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "cachyos" && "$ID_LIKE" != *"arch"* && "$ID" != "arch" ]]; then
        echo "⚠️ WARNING: This script is optimized for CachyOS / Arch-based Linux (Detected: $NAME)."
        read -p "Do you want to continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation aborted."
            exit 1
        fi
    else
        echo "✓ CachyOS / Arch Linux verified ($NAME)."
    fi
else
    echo "⚠️ Warning: Could not read /etc/os-release."
fi

echo -e "\n🔍 [Check 2/13] Checking Wayland Session..."
if [ "$XDG_SESSION_TYPE" != "wayland" ] && [ -z "$WAYLAND_DISPLAY" ]; then
    echo "⚠️ WARNING: You do not appear to be running a Wayland session!"
    echo "   Hyprland and associated tools require Wayland."
fi

#-------------------------------------------------------------------------------
# 2. HYPRLAND MANDATORY INSTALLATION (Must run before anything else)
#-------------------------------------------------------------------------------
echo -e "\n🖥️ [Step 3/13] Verifying Hyprland Compositor..."
if ! command -v hyprctl &>/dev/null && ! pacman -Qi hyprland &>/dev/null; then
    echo "⚠️ Hyprland is NOT installed! Installing Hyprland using pacman first..."
    if sudo pacman -S --noconfirm hyprland; then
        SUCCESS_STEPS+=("Hyprland core installation")
        echo "✓ Hyprland successfully installed!"
    else
        FAILED_STEPS+=("Hyprland core installation")
        echo "❌ Failed to install Hyprland package."
    fi
else
    echo "✓ Hyprland is installed."
    SUCCESS_STEPS+=("Hyprland verification")
fi

#-------------------------------------------------------------------------------
# 3. AUR Helper Check / Installation
#-------------------------------------------------------------------------------
echo -e "\n📦 [Step 4/13] Checking AUR Helper (yay/paru)..."
AUR_HELPER=""
if command -v yay &>/dev/null; then
    AUR_HELPER="yay"
elif command -v paru &>/dev/null; then
    AUR_HELPER="paru"
else
    echo "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay.git /tmp/yay_build
    (cd /tmp/yay_build && makepkg -si --noconfirm)
    rm -rf /tmp/yay_build
    AUR_HELPER="yay"
fi
echo "✓ Using AUR helper: $AUR_HELPER"

#-------------------------------------------------------------------------------
# 4. Interactive Modular Menu
#-------------------------------------------------------------------------------
if [ "$MODE" = "interactive" ]; then
    echo -e "\n📋 Select Installation Mode / اختر وضع التثبيت:"
    echo "  [1] Full Setup - Install Everything (Recommended / شامل)"
    echo "  [2] Modular Setup - Choose specific components"
    read -p "Select option [1/2] (Default: 1): " choice
    if [ "$choice" = "2" ]; then
        read -p "Install Pacman & AUR Packages? [Y/n]: " p_ans
        [[ "$p_ans" =~ ^[Nn]$ ]] && INSTALL_PACKAGES=false

        read -p "Install Configs & Keybindings? [Y/n]: " c_ans
        [[ "$c_ans" =~ ^[Nn]$ ]] && INSTALL_CONFIGS=false

        read -p "Install Custom Scripts & Tools? [Y/n]: " s_ans
        [[ "$s_ans" =~ ^[Nn]$ ]] && INSTALL_SCRIPTS=false

        read -p "Install Themes & Wallpapers? [Y/n]: " t_ans
        [[ "$t_ans" =~ ^[Nn]$ ]] && INSTALL_THEMES=false

        read -p "Restore VSCode Extensions & Settings? [Y/n]: " v_ans
        [[ "$v_ans" =~ ^[Nn]$ ]] && INSTALL_VSCODE=false
    fi
fi

#-------------------------------------------------------------------------------
# 5. Create Backup Directory
#-------------------------------------------------------------------------------
mkdir -p "$BACKUP_DIR"
echo "✓ Created backup folder at: $BACKUP_DIR"

#-------------------------------------------------------------------------------
# 6. GPU Hardware Detection & Drivers (Step 2)
#-------------------------------------------------------------------------------
echo -e "\n🎮 [Step 5/13] GPU Hardware Detection & Driver Setup..."
GPU_INFO="$(lspci -k 2>/dev/null | grep -A 2 -E "VGA|3D" || true)"
HAS_NVIDIA=false
HAS_INTEGRATED=false

if echo "$GPU_INFO" | grep -iq "nvidia"; then
    HAS_NVIDIA=true
fi
if echo "$GPU_INFO" | grep -iq -E "intel|amd|radeon"; then
    HAS_INTEGRATED=true
fi

echo "Hardware Detection Result:"
echo "  - NVIDIA Discrete GPU: $HAS_NVIDIA"
echo "  - Integrated Intel/AMD: $HAS_INTEGRATED"

if $HAS_NVIDIA && $HAS_INTEGRATED; then
    echo "⚡ Hybrid GPU detected (Integrated + NVIDIA)!"
    echo "Installing drivers and envycontrol for GPU switching..."
    sudo pacman -S --needed --noconfirm nvidia-utils mesa 2>/dev/null || true
    $AUR_HELPER -S --needed --noconfirm envycontrol 2>/dev/null || true

    if lshw 2>/dev/null | grep -iq "asus"; then
        echo "💡 Notice for ASUS Laptop Users: You can also use 'supergfxctl' for GPU switching if preferred."
    fi
    SUCCESS_STEPS+=("Hybrid GPU Drivers & EnvyControl")
elif $HAS_NVIDIA; then
    echo "🎮 Single NVIDIA GPU detected!"
    sudo pacman -S --needed --noconfirm nvidia-utils 2>/dev/null || true
    SUCCESS_STEPS+=("NVIDIA GPU Drivers")
else
    echo "💻 Integrated AMD/Intel GPU detected!"
    sudo pacman -S --needed --noconfirm mesa 2>/dev/null || true
    SUCCESS_STEPS+=("Integrated GPU Drivers")
fi

#-------------------------------------------------------------------------------
# 7. Package Installation
#-------------------------------------------------------------------------------
if $INSTALL_PACKAGES; then
    echo -e "\n📦 [Step 6/13] Restoring Packages..."
    if [ -f "$REPO_DIR/packages/pacman.txt" ]; then
        echo "Installing pacman packages..."
        sudo pacman -S --needed --noconfirm - < "$REPO_DIR/packages/pacman.txt" || FAILED_STEPS+=("Pacman Packages")
        SUCCESS_STEPS+=("Pacman Packages")
    fi

    if [ -f "$REPO_DIR/packages/aur.txt" ]; then
        echo "Installing AUR packages..."
        $AUR_HELPER -S --needed --noconfirm - < "$REPO_DIR/packages/aur.txt" 2>/dev/null || FAILED_STEPS+=("AUR Packages")
        SUCCESS_STEPS+=("AUR Packages")
    fi
fi

#-------------------------------------------------------------------------------
# 8. Restore Configurations & Keybindings
#-------------------------------------------------------------------------------
if $INSTALL_CONFIGS; then
    echo -e "\n⚙️ [Step 7/13] Deploying Configuration Files & Keybindings..."
    mkdir -p "$HOME/.config"
    rm -f "$HOME/.config/hypr/hyprland.lua" 2>/dev/null || true

    if [ -d "$REPO_DIR/configs" ]; then
        for cdir in "$REPO_DIR/configs"/*; do
            bname="$(basename "$cdir")"
            if [ -d "$cdir" ]; then
                if [ -d "$HOME/.config/$bname" ]; then
                    cp -r "$HOME/.config/$bname" "$BACKUP_DIR/" 2>/dev/null || true
                    rm -rf "$HOME/.config/$bname"
                fi
                cp -rL "$cdir" "$HOME/.config/"
                echo "  ✓ Deployed ~/.config/$bname"
            elif [ -f "$cdir" ]; then
                [ -f "$HOME/.config/$bname" ] && cp "$HOME/.config/$bname" "$BACKUP_DIR/" 2>/dev/null || true
                cp -L "$cdir" "$HOME/.config/"
            fi
        done
        rm -f "$HOME/.config/hypr/hyprland.lua" 2>/dev/null || true
        SUCCESS_STEPS+=("Configuration Files & Keybindings")
    fi
fi

# Automatically reload Hyprland live if running
if command -v hyprctl &>/dev/null; then
    hyprctl reload 2>/dev/null || true
fi

#-------------------------------------------------------------------------------
# 9. Restore Dotfiles
#-------------------------------------------------------------------------------
echo -e "\n📄 [Step 8/13] Deploying Dotfiles..."
if [ -d "$REPO_DIR/dotfiles" ]; then
    for df in "$REPO_DIR/dotfiles"/.*; do
        bname="$(basename "$df")"
        if [ "$bname" != "." ] && [ "$bname" != ".." ]; then
            [ -f "$HOME/$bname" ] && cp "$HOME/$bname" "$BACKUP_DIR/" 2>/dev/null || true
            cp -L "$df" "$HOME/"
            echo "  ✓ Deployed ~/$bname"
        fi
    done
    SUCCESS_STEPS+=("Dotfiles")
fi

#-------------------------------------------------------------------------------
# 10. Restore Helper Scripts
#-------------------------------------------------------------------------------
if $INSTALL_SCRIPTS; then
    echo -e "\n📜 [Step 9/13] Deploying Custom Scripts (~/.local/share/bin)..."
    mkdir -p "$HOME/.local/share/bin"
    if [ -d "$REPO_DIR/scripts" ]; then
        cp -rL "$REPO_DIR/scripts"/.* "$HOME/.local/share/bin/" 2>/dev/null || true
        cp -rL "$REPO_DIR/scripts"/* "$HOME/.local/share/bin/" 2>/dev/null || true
        chmod +x "$HOME/.local/share/bin"/* 2>/dev/null || true
        echo "✓ Custom scripts deployed and made executable."
        SUCCESS_STEPS+=("Custom Scripts")
    fi
fi

#-------------------------------------------------------------------------------
# 11. Fonts & Wallpapers
#-------------------------------------------------------------------------------
if $INSTALL_THEMES; then
    echo -e "\n🎨 [Step 10/13] Deploying Fonts and Themes..."
    if [ -d "$REPO_DIR/fonts" ] && [ "$(ls -A "$REPO_DIR/fonts" 2>/dev/null)" ]; then
        mkdir -p "$HOME/.local/share/fonts"
        cp -rL "$REPO_DIR/fonts"/* "$HOME/.local/share/fonts/" 2>/dev/null || true
        fc-cache -fv &>/dev/null || true
        echo "✓ Fonts installed and font cache updated."
    fi

    if [ -d "$REPO_DIR/wallpapers" ]; then
        mkdir -p "$HOME/.config/hypr/themes"
        cp -rL "$REPO_DIR/wallpapers"/* "$HOME/.config/hypr/themes/" 2>/dev/null || true
        echo "✓ Wallpapers deployed."
    fi

    # Set active wallpaper link and apply via swww
    mkdir -p "$HOME/.cache/hyde"
    ACTIVE_WALL=""
    if [ -f "$HOME/.config/hyde/themes/Gruvbox Retro/wallpapers/background_for_me.jpg" ]; then
        ACTIVE_WALL="$HOME/.config/hyde/themes/Gruvbox Retro/wallpapers/background_for_me.jpg"
    else
        ACTIVE_WALL="$(find "$HOME/.config/hyde/themes" -type f \( -name "*.jpg" -o -name "*.png" \) 2>/dev/null | head -n 1)"
    fi

    if [ -n "$ACTIVE_WALL" ]; then
        ln -sf "$ACTIVE_WALL" "$HOME/.cache/hyde/wall.set"
        if command -v swww &>/dev/null; then
            swww-daemon 2>/dev/null || swww init 2>/dev/null || true
            swww img "$ACTIVE_WALL" 2>/dev/null || true
        fi
        echo "✓ Active wallpaper configured ($ACTIVE_WALL)."
    fi
    SUCCESS_STEPS+=("Fonts & Themes")
fi

#-------------------------------------------------------------------------------
# 12. Enable Systemd User Services
#-------------------------------------------------------------------------------
if $INSTALL_SERVICES && [ -f "$REPO_DIR/services/user_services.txt" ]; then
    echo -e "\n🔄 [Step 11/13] Enabling Systemd User Services..."
    while read -r srv; do
        if [ -n "$srv" ]; then
            systemctl --user enable "$srv" 2>/dev/null || true
            echo "  ✓ Enabled user service: $srv"
        fi
    done < "$REPO_DIR/services/user_services.txt"
    SUCCESS_STEPS+=("Systemd User Services")
fi

#-------------------------------------------------------------------------------
# 13. VSCode Restoration
#-------------------------------------------------------------------------------
if $INSTALL_VSCODE && [ -d "$REPO_DIR/vscode" ]; then
    echo -e "\n💻 [Step 12/13] Restoring VSCode Configs & Extensions..."
    VSCODE_TARGET="$HOME/.config/Code/User"
    [ -d "$HOME/.config/Code - OSS/User" ] && VSCODE_TARGET="$HOME/.config/Code - OSS/User"
    mkdir -p "$VSCODE_TARGET"

    [ -f "$REPO_DIR/vscode/settings.json" ] && cp "$REPO_DIR/vscode/settings.json" "$VSCODE_TARGET/"
    [ -f "$REPO_DIR/vscode/keybindings.json" ] && cp "$REPO_DIR/vscode/keybindings.json" "$VSCODE_TARGET/"

    VS_BIN=""
    command -v code &>/dev/null && VS_BIN="code"
    command -v code-oss &>/dev/null && VS_BIN="code-oss"

    if [ -n "$VS_BIN" ] && [ -f "$REPO_DIR/vscode/extensions.txt" ]; then
        while read -r ext; do
            [ -n "$ext" ] && $VS_BIN --install-extension "$ext" --force &>/dev/null || true
        done < "$REPO_DIR/vscode/extensions.txt"
        echo "✓ VSCode extensions restored."
    fi
    SUCCESS_STEPS+=("VSCode Setup")
fi

#-------------------------------------------------------------------------------
# Summary Report
#-------------------------------------------------------------------------------
echo -e "\n================================================================="
echo "   📊 Installation Summary Report / تقرير التثبيت الختامي"
echo "================================================================="

echo "Successful Components (${#SUCCESS_STEPS[@]}):"
for s in "${SUCCESS_STEPS[@]}"; do
    echo "  [✓] $s"
done

if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
    echo -e "\nFailed Components (${#FAILED_STEPS[@]}):"
    for f in "${FAILED_STEPS[@]}"; do
        echo "  [❌] $f"
    done
else
    echo -e "\n🎉 All components were restored with zero errors!"
fi

echo -e "\n📌 Post-Installation Guidelines:"
echo "  1. Reboot or relogin to apply environment changes."
if $HAS_NVIDIA && $HAS_INTEGRATED; then
    echo "  2. Switch GPU modes anytime using EnvyControl:"
    echo "     - Hybrid mode:    sudo envycontrol -s hybrid"
    echo "     - Integrated:     sudo envycontrol -s integrated"
    echo "     - NVIDIA mode:    sudo envycontrol -s nvidia"
fi
echo "  3. Use post-install GUI tools in ./tools/ anytime:"
echo "     - python3 tools/nightlight-config.py"
echo "     - python3 tools/display-config.py"
echo "     - python3 tools/monitor-alignment.py"
echo "================================================================="
