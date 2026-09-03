# f3n2wm Beginner's Guide

## Quick Start

```bash
git clone https://github.com/xyragen/f3n2wm.git
cd f3n2wm
./scripts/setup.sh --auto
```

Log out, then run `startx`.

## Keybindings

| Key | Action |
|-----|--------|
| Mod4+Return | Open terminal |
| Mod4+d | App launcher (rofi) |
| Mod4+h/j/k/l | Focus left/down/up/right |
| Mod4+Shift+h/j/k/l | Move window |
| Mod4+Space | Next layout |
| Mod4+1-0 | Switch workspace |
| Mod4+Shift+1-0 | Move window to workspace |
| Mod4+q | Close window |
| Mod4+f | Fullscreen |
| Mod4+t | Toggle floating |
| Mod4+r | Reload config |
| Mod4+F2 | Restart |
| Mod4+F3 | Exit |

## Config

Edit `~/.config/f3n2wm/f3n2wm.toml` and press `Mod4+r` to reload.

## Layouts

- **master-stack**: Master + stack (default)
- **spiral**: Fibonacci spiral
- **monocle**: Fullscreen
- **grid**: Grid
- **tabbed**: Tabbed

## Dependencies

- xorg-server
- xinit
- luajit
- libx11-dev
- libxinerama-dev
- rofi
- alacritty (or kitty)