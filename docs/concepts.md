# Tiling Concepts

## Tiling vs Floating

- **Tiling**: Windows arranged automatically, no overlap
- **Floating**: Windows can be positioned freely (dialogs, popups auto-float)
- Toggle with `Mod4+t`

## Workspaces

- `Mod4+1` through `Mod4+0` to switch
- `Mod4+Shift+1-0` to move window to workspace
- 10 workspaces by default

## Layouts

- **master-stack**: Master window + stack (default)
- **spiral**: Fibonacci spiral
- **monocle**: Fullscreen
- **grid**: Grid arrangement
- **tabbed**: Tab bar

Cycle with `Mod4+Space`

## Gaps & Borders

```toml
gap_size = 8        # Space between windows
border_width = 2    # Border thickness
```

## Window Rules

Auto-float or assign apps to workspaces:

```toml
[[rules]]
match = "Gimp"
float = true
workspace = 3
```

## Custom Layouts

Create `~/.config/f3n2wm/layouts/my_layout.lua`:

```lua
local my_layout = {}
my_layout.name = "my-layout"

function my_layout.arrange(windows, rect, config)
    for i, w in ipairs(windows) do
        w:update_geometry(rect.x, rect.y + (i-1)*50, rect.width, 50)
    end
end

return my_layout
```

## IPC Commands

```bash
echo "list_workspaces" | socat - UNIX-CONNECT:/tmp/f3n2wm-ipc.sock
f3n2wm-ipc switch_workspace 3