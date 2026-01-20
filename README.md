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

- `Super + hjkl` – focus windows
- `Super + Shift + hjkl` – move windows
- `Super + 1-9` – switch workspaces
- `Super + Return` – open terminal
- `Super + Space` – app launcher
- `Super + Q` – close window
- `Super + F` – fullscreen
- `Super + V` – toggle floating

## Customize

Edit `~/.config/` to customize. Waybar and dunst symlinks can be broken to customize independently.
