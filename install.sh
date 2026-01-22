#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Preserve user's home when run with sudo
if [ "$SUDO_USER" ]; then
    USER_HOME="/home/$SUDO_USER"
else
    USER_HOME="$HOME"
fi

DOTS_DIR="$USER_HOME/.local/share/hyprarch"
CONFIG_DIR="$USER_HOME/.config"

# Detect host
detect_host() {
    if lspci | grep -q "Intel.*Arc"; then
        echo "laptop"
    elif lspci | grep -q "NVIDIA"; then
        echo "pc"
    else
        echo "laptop"  # default
    fi
}

HOST=$(detect_host)
echo "Detected host: $HOST"

# Install AUR helper if not present
if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
    echo "Installing paru (AUR helper)..."
    pacman -S --noconfirm base-devel
    rm -rf /tmp/paru
    sudo -u "$SUDO_USER" bash -c 'cd /tmp && git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si'
fi

# Install packages (we're already root from sudo ./install.sh)
echo "Installing packages..."
pacman -S - < "$REPO_DIR/packages/base.txt" || echo "Warning: pacman failed"

# Install AUR packages as user (AUR helpers must run as non-root)
AUR_HELPER=$(command -v paru || command -v yay)
if [ -n "$AUR_HELPER" ]; then
    echo "Installing AUR packages..."
    sudo -u "$SUDO_USER" bash -c "$AUR_HELPER -S - < '$REPO_DIR/packages/aur.txt'" || echo "Warning: AUR install failed"
else
    echo "Error: No AUR helper available."
    exit 1
fi

echo "Package installation step complete."

# Create directories
mkdir -p "$DOTS_DIR"
mkdir -p "$CONFIG_DIR"

# Copy defaults
echo "Setting up defaults..."
echo "Copying from: $REPO_DIR/defaults"
echo "Copying to: $DOTS_DIR"

cp -rv "$REPO_DIR/defaults/hypr" "$DOTS_DIR/" || { echo "Failed to copy hypr"; exit 1; }
cp -rv "$REPO_DIR/defaults/waybar" "$DOTS_DIR/" || { echo "Failed to copy waybar"; exit 1; }
cp -rv "$REPO_DIR/defaults/dunst" "$DOTS_DIR/" || { echo "Failed to copy dunst"; exit 1; }
cp -rv "$REPO_DIR/defaults/ghostty" "$DOTS_DIR/" || { echo "Failed to copy ghostty"; exit 1; }
cp -rv "$REPO_DIR/defaults/fontconfig" "$DOTS_DIR/" || { echo "Failed to copy fontconfig"; exit 1; }
cp -rv "$REPO_DIR/defaults/shell" "$DOTS_DIR/" || { echo "Failed to copy shell"; exit 1; }

# Make shell scripts executable
chmod +x "$DOTS_DIR/shell"/*.sh

ls -la "$DOTS_DIR"

# Fix ownership if run with sudo
if [ "$SUDO_USER" ]; then
    chown -R "$SUDO_USER:$SUDO_USER" "$DOTS_DIR"
    chown -R "$SUDO_USER:$SUDO_USER" "$CONFIG_DIR"
fi

# Create user config structure
echo "Generating user configs..."
mkdir -p "$CONFIG_DIR/hypr"
mkdir -p "$CONFIG_DIR/waybar"
mkdir -p "$CONFIG_DIR/dunst"
mkdir -p "$CONFIG_DIR/ghostty"

# Generate hyprland.conf with source chain
cat > "$CONFIG_DIR/hypr/hyprland.conf" << 'EOF'
source = ~/.local/share/hyprarch/hypr/hyprland.conf
source = ~/.local/share/hyprarch/hypr/env.conf
source = ~/.config/hypr/env.conf
EOF

# Generate host-specific env and copy hyprlock
mkdir -p "$CONFIG_DIR/hypr"
if [ "$HOST" = "laptop" ]; then
    cp "$REPO_DIR/hosts/laptop/hypr/env.conf" "$CONFIG_DIR/hypr/env.conf"
    cp "$REPO_DIR/hosts/laptop/hypr/monitors.conf" "$CONFIG_DIR/hypr/"
else
    cp "$REPO_DIR/hosts/pc/hypr/env.conf" "$CONFIG_DIR/hypr/env.conf"
    cp "$REPO_DIR/hosts/pc/hypr/monitors.conf" "$CONFIG_DIR/hypr/"
fi

# Copy hyprlock and hypridle configs (they look for these directly)
cp "$REPO_DIR/defaults/hypr/hyprlock.conf" "$CONFIG_DIR/hypr/hyprlock.conf"
cp "$REPO_DIR/defaults/hypr/hypridle.conf" "$CONFIG_DIR/hypr/hypridle.conf"

# Symlink waybar (user can break symlink to customize)
rm -f "$CONFIG_DIR/waybar/config" "$CONFIG_DIR/waybar/style.css" "$CONFIG_DIR/waybar/power-menu.sh"
ln -s "$DOTS_DIR/waybar/config" "$CONFIG_DIR/waybar/config"
ln -s "$DOTS_DIR/waybar/style.css" "$CONFIG_DIR/waybar/style.css"
chmod +x "$DOTS_DIR/waybar/power-menu.sh"
ln -s "$DOTS_DIR/waybar/power-menu.sh" "$CONFIG_DIR/waybar/power-menu.sh"

# Symlink dunst
rm -f "$CONFIG_DIR/dunst/dunstrc"
ln -s "$DOTS_DIR/dunst/dunstrc" "$CONFIG_DIR/dunst/dunstrc"

# Symlink ghostty
mkdir -p "$CONFIG_DIR/ghostty"
rm -f "$CONFIG_DIR/ghostty/config"
ln -s "$DOTS_DIR/ghostty/config" "$CONFIG_DIR/ghostty/config"

# Symlink fontconfig
mkdir -p "$CONFIG_DIR/fontconfig/conf.d"
rm -f "$CONFIG_DIR/fontconfig/conf.d/local.conf"
ln -s "$DOTS_DIR/fontconfig/local.conf" "$CONFIG_DIR/fontconfig/conf.d/local.conf"

echo "✓ Installation complete!"
echo "✓ Host: $HOST"
echo "✓ Defaults: ~/.local/share/hyprarch"
echo "✓ User configs: ~/.config"
echo ""
echo "Next: Start Hyprland (e.g., Ctrl+Alt+F2 to switch to TTY, then 'Hyprland')"