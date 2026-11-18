# Hyprland Dotfiles

Portable Linux desktop environment configuration.

## What's Included

| Tool | Purpose |
|------|---------|
| Hyprland | Wayland compositor |
| Waybar | Status bar |
| Rofi | App launcher / power menu |
| Kitty | Terminal |
| Swww / Awww | Wallpaper daemon |
| Swaync | Notification daemon |
| Thunar | File manager |
| Zed | Editor (AI agent model + remote dev box over SSH) |

## Quick Start

1. **Install dependencies** (see below).
2. **Clone** this repo into `~/.config` (or use GNU Stow / symlinks).
3. **Adjust monitor setup** in `hypr/hyprland.conf` for your machine.
4. **Set your browser** via the `$browser` variable in `hypr/hyprland.conf`.
5. **Log out / log in** to Hyprland.

## Dependencies

### Core

```bash
# Arch-based
sudo pacman -S hyprland waybar rofi-wayland kitty swww thunar swaync

# You also need a PolicyKit authentication agent, e.g.:
sudo pacman -S polkit-kde-agent
```

### Fonts

- **JetBrainsMono Nerd Font** (terminal, bar, rofi)
- **Noto Sans** (window titles in waybar)
- **Roboto** (fallback)

Install on Arch:
```bash
sudo pacman -S ttf-jetbrains-mono-nerd ttf-noto-sans ttf-roboto
```

### Themes & Icons

- Cursor: `Bibata-Original-Amber`
- Icon theme: `Papirus-Dark`

```bash
yay -S bibata-cursor-theme-bin papirus-icon-theme
```

### Utilities Used by Scripts

| Tool | Used By | Package (Arch) |
|------|---------|----------------|
| `grimblast` | Screenshots | `hyprland-contrib` or `grimblast-git` |
| `hyprlock` | Lock screen | `hyprlock` |
| `nmcli` | WiFi menu | `networkmanager` |
| `wpctl` / `wireplumber` | Volume keys | `wireplumber` |
| `pavucontrol` | Audio GUI | `pavucontrol` |
| `brightnessctl` | Brightness keys | `brightnessctl` |
| `playerctl` | Media keys | `playerctl` |
| `jq` | JSON parsing in scripts | `jq` |
| `curl` / `wget` | Wallpaper engine | `curl`, `wget` |
| `geoclue` | Location sync (optional) | `geoclue` |

### Optional / Custom Tools

These are **commented out** in the config by default. Uncomment the binds if you install them:

- `~/.local/bin/organize` — custom download folder organizer
- `~/cortex-vault/scripts/cortex-pull` — custom vault sync script
- `vim-cheat` — custom vim cheat-sheet viewer

## System-Specific Notes

### Monitors

The generic config uses auto-detection:

```ini
monitor=,preferred,auto,auto
```

My personal 3-monitor setup is commented out in `hypr/hyprland.conf`. Uncomment and edit the lines to match your displays.

### Wallpaper Daemon

My system uses a custom build called `awww` (a fork/wrapper of `swww`). The scripts automatically prefer `awww` if installed, otherwise fall back to standard `swww`. For a fresh machine, just install `swww` from your distro repos.

### WiFi Interface

`waybar/scripts/wifi-menu.sh` auto-detects your wireless interface via `nmcli`. It falls back to `wlo1` if detection fails.

### Polkit Agent Path

The agent path varies between distros (`/usr/lib/...` vs `/usr/libexec/...`). The config tries common locations automatically.

## Keybinds Cheat Sheet

| Key | Action |
|-----|--------|
| `Super + T` | Terminal |
| `Super + E` | File manager |
| `Super + Space` | Rofi launcher |
| `Super + B` | Browser (set via `$browser`) |
| `Super + S` | Screenshot area |
| `Super + Shift + S` | Screenshot screen |
| `Super + L` | Lock screen |
| `Super + Period` | Random wallpaper |
| `Super + A` | Audio control GUI |
| `Super + R` | Restart waybar |
| `Super + Shift + R` | Toggle waybar visibility |
| `Super + [1-0]` | Switch workspace |
| `Super + Shift + [1-0]` | Move window to workspace |

## Color Theme

Gruvbox Dark across all tools (Hyprland borders, Kitty, Waybar, Rofi).

## Credits

- Rofi themes based on [adi1090x/rofi](https://github.com/adi1090x/rofi)
