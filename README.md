# hyprarch

Arch + Hyprland bootstrap for laptop (Intel Core Ultra 9 185H).

## Install

```bash
git clone https://github.com/shivamx96/hyprarch.git
cd hyprarch
chmod +x install.sh
./install.sh
```

The script will:
- Detect hardware
- Install packages (Hyprland, waybar, dunst, ghostty, etc.)
- Set up defaults in `~/.local/share/hyprarch/`
- Generate user configs in `~/.config/`

## Keybindings

### Applications
- `Super + Return` – terminal (ghostty)
- `Super + B` – web browser (Zen)
- `Super + Shift + B` – Bluetooth manager
- `Super + F` – file manager (Thunar)
- `Super + Space` – app launcher (Fuzzel)
- `Super + L` – lock screen

### Window Management
- `Super + Arrow Keys` – focus windows
- `Super + Q` – close window
- `Super + V` – toggle floating
- `Super + F` – fullscreen

### Workspaces
- `Super + 1-9/0` – switch workspaces (1-10)
- `Super + Shift + 1-9/0` – move window to workspace

### Multimedia
- `Fn + Volume Up/Down` – adjust volume (with OSD)
- `Fn + Mute` – toggle mute
- `Fn + Brightness Up/Down` – adjust brightness (with OSD)

## Features

- **Laptop-optimized** for Intel Core Ultra 9 185H with Arc iGPU
- **Audio support** via PipeWire with Pavucontrol GUI
- **Bluetooth** with Blueman GUI manager
- **Power management** via Hypridle (auto-lock, brightness control, suspend)
- **Clean notifications** via Dunst
- **Status bar** with Waybar showing volume, brightness, network, battery, etc.

## Customize

Edit `~/.config/` to customize. Waybar, dunst, and ghostty symlinks can be broken to customize independently.
