# f3n2wm

A dynamic tiling window manager for Linux, written in LuaJIT with X11 FFI bindings.

## Features

- TOML configuration
- Lua extensibility (custom layouts, hooks, commands)
- Dynamic tiling with multiple layouts
- Keyboard-first workflow
- Low resource usage

## Install

```bash
git clone https://github.com/xyragen/f3n2wm.git
cd f3n2wm
./setup.sh
```

For automatic setup:
```bash
./setup.sh --auto
```

## After Setup

1. Log out of your current session
2. Log in to a TTY (Ctrl+Alt+F2) or use your display manager
3. Start f3n2wm:
   ```bash
   startx
   ```

Or if you have a display manager (GDM, SDDM, LightDM), select "xinit" or "f3n2wm" from the session menu.

## Dependencies

- xorg-server (X server)
- xinit (provides `startx`)
- luajit
- libx11-dev
- libxinerama-dev
- rofi
- alacritty (or kitty)

## Config

Edit `~/.config/f3n2wm/f3n2wm.toml` and press `Mod4+r` to reload.

## Keybindings

| Key | Action |
|-----|--------|
| Mod4+Return | Terminal |
| Mod4+d | App launcher |
| Mod4+h/j/k/l | Focus |
| Mod4+Space | Next layout |
| Mod4+1-0 | Switch workspace |
| Mod4+q | Close window |
| Mod4+f | Fullscreen |
| Mod4+t | Toggle floating |
| Mod4+r | Reload config |

## Layouts

- master-stack, spiral, monocle, grid, tabbed

## Docs

- [Beginner's Guide](docs/beginner-guide.md)
- [Tiling Concepts](docs/concepts.md)

## License

MIT