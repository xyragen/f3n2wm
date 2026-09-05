local registry = require("window.registry")
local object = require("window.object")
local actions = require("window.actions")

registry.Window = object.Window
actions.install()

local window = registry

function window.focus_next()
    if not window.wm or not window.wm.workspaces then return end
    local ws = window.wm.workspaces:get_current()
    if ws then ws:focus_next() end
end

function window.focus_prev()
    if not window.wm or not window.wm.workspaces then return end
    local ws = window.wm.workspaces:get_current()
    if ws then ws:focus_prev() end
end

function window.focus_direction(dir)
    if not window.wm or not window.wm.workspaces then return end
    local ws = window.wm.workspaces:get_current()
    if ws then ws:focus_direction(dir) end
end

function window.move_focused(direction)
    if not window.wm or not window.wm.workspaces then return end
    local ws = window.wm.workspaces:get_current()
    if ws then ws:move_focused(direction) end
end

function window.close_focused()
    if not window.wm or not window.wm.workspaces then return end
    local ws = window.wm.workspaces:get_current()
    if ws then ws:close_focused() end
end

function window.kill_focused()
    if not window.wm or not window.wm.workspaces then return end
    local ws = window.wm.workspaces:get_current()
    if ws then
        local w = ws:get_focused()
        if w then w:kill() end
    end
end

function window.next_layout()
    if not window.wm or not window.wm.workspaces then return end
    local ws = window.wm.workspaces:get_current()
    if ws then ws:next_layout() end
end

function window.prev_layout()
    if not window.wm or not window.wm.workspaces then return end
    local ws = window.wm.workspaces:get_current()
    if ws then ws:prev_layout() end
end

function window.toggle_floating_focused()
    if not window.wm or not window.wm.workspaces then return end
    local ws = window.wm.workspaces:get_current()
    if ws then
        local w = ws:get_focused()
        if w then w:toggle_floating() end
    end
end

function window.maximize_focused()
    if not window.wm or not window.wm.workspaces then return end
    local ws = window.wm.workspaces:get_current()
    if ws then
        local w = ws:get_focused()
        if w then w:maximize() end
    end
end

function window.fullscreen_focused()
    if not window.wm or not window.wm.workspaces then return end
    local ws = window.wm.workspaces:get_current()
    if ws then
        local w = ws:get_focused()
        if w then w:toggle_fullscreen() end
    end
end

function window.swap_master()
    if not window.wm or not window.wm.workspaces then return end
    local ws = window.wm.workspaces:get_current()
    if ws then ws:swap_master() end
end

function window.inc_master()
    local wm = window.wm
    if not wm then return end
    wm.master_count = wm.master_count + 1
    local ws = wm.workspaces and wm.workspaces:get_current()
    if ws then ws:arrange() end
end

function window.dec_master()
    local wm = window.wm
    if not wm then return end
    wm.master_count = math.max(1, wm.master_count - 1)
    local ws = wm.workspaces and wm.workspaces:get_current()
    if ws then ws:arrange() end
end

function window.inc_margin()
    local wm = window.wm
    if not wm then return end
    wm.gap_size = wm.gap_size + 2
    local ws = wm.workspaces and wm.workspaces:get_current()
    if ws then ws:arrange() end
end

function window.dec_margin()
    local wm = window.wm
    if not wm then return end
    wm.gap_size = math.max(0, wm.gap_size - 2)
    local ws = wm.workspaces and wm.workspaces:get_current()
    if ws then ws:arrange() end
end

function window.reload()
    if window.wm then window.wm:reload_config() end
end

function window.restart()
    if window.wm then window.wm:restart() end
end

function window.exit()
    if window.wm then window.wm:exit() end
end

function window.focus_urgent()
    local urgent = window.get_urgent()
    if #urgent > 0 then
        if window.wm and window.wm.workspaces then
            local ws = window.wm.workspaces:get_current()
            if ws then ws:focus_window(urgent[1].id) end
        end
    end
end

function window.go_back()
    if window.wm and window.wm.workspaces then
        window.wm.workspaces:go_back()
    end
end

function window.toggle_split()
    local wm = window.wm
    if not wm then return end
    wm.layout_split_vertical = not wm.layout_split_vertical
    local ws = wm.workspaces and wm.workspaces:get_current()
    if ws then ws:arrange() end
end

function window.layout_info()
    local wm = window.wm
    if not wm or not wm.workspaces then return end
    local ws = wm.workspaces:get_current()
    if ws then
        local names = wm.layouts.list_layout_names()
        local idx = ws.layout_index
        print("Layout: " .. (names[idx] or "unknown") ..
              " | Windows: " .. #ws.windows ..
              " | Master: " .. ws.master_count)
    end
end

return window