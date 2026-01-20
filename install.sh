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

# Install packages
echo "Installing packages..."
pacman -S --noconfirm - < "$REPO_DIR/packages/base.txt"

if command -v yay &> /dev/null || command -v paru &> /dev/null; then
    AUR_HELPER=$(command -v paru || command -v yay)
    $AUR_HELPER -S --noconfirm - < "$REPO_DIR/packages/aur.txt"
else
    echo "Warning: No AUR helper found. Install yay or paru manually."
fi

# Create directories
mkdir -p "$DOTS_DIR"
mkdir -p "$CONFIG_DIR"

# Copy defaults
echo "Setting up defaults..."
cp -r "$REPO_DIR/defaults/hypr" "$DOTS_DIR/"
cp -r "$REPO_DIR/defaults/waybar" "$DOTS_DIR/"
cp -r "$REPO_DIR/defaults/dunst" "$DOTS_DIR/"
cp -r "$REPO_DIR/defaults/ghostty" "$DOTS_DIR/"
cp -r "$REPO_DIR/defaults/shell" "$DOTS_DIR/"

# Fix ownership if run with sudo
if [ "$SUDO_USER" ]; then
    chown -R "$SUDO_USER:$SUDO_USER" "$DOTS_DIR" "$CONFIG_DIR"
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

# Generate host-specific env
mkdir -p "$CONFIG_DIR/hypr"
if [ "$HOST" = "laptop" ]; then
    cp "$REPO_DIR/hosts/laptop/hypr/env.conf" "$CONFIG_DIR/hypr/env.conf"
    cp "$REPO_DIR/hosts/laptop/hypr/monitors.conf" "$CONFIG_DIR/hypr/"
else
    cp "$REPO_DIR/hosts/pc/hypr/env.conf" "$CONFIG_DIR/hypr/env.conf"
    cp "$REPO_DIR/hosts/pc/hypr/monitors.conf" "$CONFIG_DIR/hypr/"
fi

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

echo "✓ Installation complete!"
echo "✓ Host: $HOST"
echo "✓ Defaults: ~/.local/share/hyprarch"
echo "✓ User configs: ~/.config"
echo ""
echo "Next: Start Hyprland (e.g., Ctrl+Alt+F2 to switch to TTY, then 'Hyprland')"