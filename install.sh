#!/usr/bin/env bash
set -e

# Must run as root
if [ "$EUID" -ne 0 ]; then
    echo "Run with sudo: sudo ./install.sh"
    exit 1
fi

if [ -z "$SUDO_USER" ]; then
    echo "Run with sudo, not as root directly: sudo ./install.sh"
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="/home/$SUDO_USER"

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
    pacman -S --noconfirm --needed base-devel
    rm -rf /tmp/paru
    sudo -u "$SUDO_USER" bash -c 'cd /tmp && git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si'
fi

# Install packages (we're already root from sudo ./install.sh)
echo "Installing base packages..."
pacman -S --noconfirm --needed - < "$REPO_DIR/packages/base.txt" || echo "Warning: pacman failed"

# Install host-specific packages
HOST_PKGS="$REPO_DIR/hosts/$HOST/packages.txt"
if [ -f "$HOST_PKGS" ]; then
    echo "Installing $HOST packages..."
    pacman -S --noconfirm --needed - < "$HOST_PKGS" || echo "Warning: host package install failed"
fi

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

# Enable and start Bluetooth service
echo "Setting up Bluetooth..."
systemctl enable bluetooth.service
systemctl start bluetooth.service || echo "Warning: Could not start bluetooth service (may need manual setup)"

# Enable auto-login on TTY1
echo "Setting up auto-login..."
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << AUTOLOGIN
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\\\u' --noclear --autologin $SUDO_USER %I \$TERM
AUTOLOGIN

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
cp -rv "$REPO_DIR/defaults/wallpapers" "$DOTS_DIR/" || { echo "Failed to copy wallpapers"; exit 1; }

# Make shell scripts executable
chmod +x "$DOTS_DIR/shell"/*.sh

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

# Copy host-specific configs
mkdir -p "$CONFIG_DIR/hypr"
HOST_DIR="$REPO_DIR/hosts/$HOST/hypr"
if [ -d "$HOST_DIR" ]; then
    cp "$HOST_DIR/env.conf" "$CONFIG_DIR/hypr/env.conf"
    cp "$HOST_DIR/monitors.conf" "$CONFIG_DIR/hypr/"
else
    echo "Error: No host config found at $HOST_DIR"
    exit 1
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

# Source hyprarch profile from user's shell login config
PROFILE_SOURCE="source $DOTS_DIR/shell/profile"
# Detect user's shell and add to the right profile
USER_SHELL=$(getent passwd "$SUDO_USER" | cut -d: -f7)
if [[ "$USER_SHELL" == */zsh ]]; then
    SHELL_RC="$USER_HOME/.zprofile"
else
    SHELL_RC="$USER_HOME/.bash_profile"
fi
touch "$SHELL_RC"
if ! grep -qF "$PROFILE_SOURCE" "$SHELL_RC"; then
    echo "$PROFILE_SOURCE" >> "$SHELL_RC"
fi

# Fix ownership (must be after all config generation)
chown -R "$SUDO_USER:$SUDO_USER" "$DOTS_DIR"
chown -R "$SUDO_USER:$SUDO_USER" "$CONFIG_DIR"
chown "$SUDO_USER:$SUDO_USER" "$SHELL_RC"
[ -d "$USER_HOME/.cache" ] && chown -R "$SUDO_USER:$SUDO_USER" "$USER_HOME/.cache"
[ -d "$USER_HOME/.local" ] && chown -R "$SUDO_USER:$SUDO_USER" "$USER_HOME/.local"

# Configure NVIDIA DRM and early KMS
if [ "$HOST" = "pc" ]; then
    echo "Configuring NVIDIA DRM..."
    mkdir -p /etc/modprobe.d
    echo "options nvidia_drm modeset=1" > /etc/modprobe.d/nvidia.conf

    # Install headers for all installed kernels
    for kern in $(pacman -Qqe | grep "^linux" | grep -v headers); do
        if pacman -Si "${kern}-headers" &> /dev/null; then
            pacman -S --noconfirm --needed "${kern}-headers"
        fi
    done

    # Ensure DKMS modules are built for all kernels
    if command -v dkms &> /dev/null; then
        dkms autoinstall
    fi

    # Add NVIDIA modules to mkinitcpio if not already present
    NVIDIA_MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
    if [ -f /etc/mkinitcpio.conf ]; then
        CURRENT_MODULES=$(grep "^MODULES=" /etc/mkinitcpio.conf | sed 's/MODULES=(\(.*\))/\1/')
        NEEDS_UPDATE=false
        for mod in $NVIDIA_MODULES; do
            if ! echo "$CURRENT_MODULES" | grep -qw "$mod"; then
                NEEDS_UPDATE=true
                break
            fi
        done
        if [ "$NEEDS_UPDATE" = true ]; then
            sed -i "s/^MODULES=(\(.*\))/MODULES=(\1 $NVIDIA_MODULES)/" /etc/mkinitcpio.conf
            # Clean up any double spaces
            sed -i 's/MODULES=(  */MODULES=(/' /etc/mkinitcpio.conf
            echo "Rebuilding initramfs..."
            mkinitcpio -P
        fi
    fi
fi

echo ""
echo "✓ Installation complete!"
echo "✓ Host: $HOST"
echo "✓ Defaults: ~/.local/share/hyprarch"
echo "✓ User configs: ~/.config"
echo "✓ Auto-login and Hyprland auto-start configured"
if [ "$HOST" = "pc" ]; then
    echo "✓ NVIDIA DRM modeset and early KMS configured"
fi
echo ""
echo "Reboot to launch into Hyprland."