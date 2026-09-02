local window = {}

window.windows = {}
window.wm = nil

function window.set_wm(wm)
    window.wm = wm
end

window.Window = {}
window.Window.__index = window.Window

function window.Window:new(id)
    local w = setmetatable({}, window.Window)
    w.id = id
    w.x = 0
    w.y = 0
    w.width = 0
    w.height = 0
    w.border_width = 0
    w.visible = false
    w.mapped = false
    w.focused = false
    w.floating = false
    w.maximized = false
    w.maximized_h = false
    w.maximized_v = false
    w.fullscreen = false
    w.minimized = false
    w.sticky = false
    w.above = false
    w.below = false
    w.urgent = false
    w.skip_taskbar = false
    w.skip_pager = false
    w.always_on_top = false
    w.decorations = true
    w.titlebars = false
    w.workspace = nil
    w.monitor = nil
    w.pid = nil
    w.class = nil
    w.name = nil
    w.instance = nil
    w.role = nil
    w.transient_for = nil
    w.modal = false
    w.hint = nil
    w.can_resize = true
    w.can_close = true
    w.can_maximize = true
    w.can_minimize = true
    w.can_fullscreen = true
    w.opacity = 1.0
    w.z_order = 0
    w.tiled = false
    w.geometry = nil
    w.last_geometry = nil
    w.initializing = true
    w.float_x = nil
    w.float_y = nil
    w.float_width = nil
    w.float_height = nil
    w.dragging = false
    w.resizing = false
    w.resize_grip = nil
    w.is_new = false
    w.is_destroying = false
    w.is_swallowed = false
    w.last_activated_time = 0
    w.last_hovered_time = 0
    w.save_geometry = false
    w.save_state = false
    w.has_alpha = false
    w.has_border = true
    w.border_pixel = 0
    w.has_input = true
    w.allowed_actions = {}
    return w
end

function window.Window:update_geometry(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function window.Window:get_geometry()
    return {
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height,
    }
end

function window.Window:set_border(width, color_hex, focused)
    local wm = window.wm
    if not wm or not self.has_border then return end
    local X11 = wm.x11
    local pixel = X11.alloc_color(color_hex)
    if pixel == 0 then pixel = 0 end
    X11.set_window_border_width(self.id, wm.config.border_width)
    X11.set_window_border(self.id, pixel)
    self.border_pixel = pixel
end

function window.Window:focus()
    if self.is_destroying then return end
    local wm = window.wm
    if not wm then return end
    local X11 = wm.x11

    self.focused = true
    X11.set_input_focus(self.id)
    X11.add_wm_state(self.id, X11.intern_atom("_NET_WM_STATE_DEMANDS_ATTENTION"))

    if wm then
        wm:update_active_window(self.id)
    end

    local focus_color = wm.config.colors.border_focus
    if not focus_color then focus_color = wm.config.border_focus end
    self:set_border(wm.config.border_width, focus_color, true)

    local ws = wm.workspaces:get_current()
    if ws then
        ws:raise_window(self.id)
    end

    wm.hooks.fire("window_focus", self, ws)
end

function window.Window:unfocus()
    local wm = window.wm
    if not wm then return end
    self.focused = false

    local unfocus_color = wm.config.colors.border_unfocus
    if not unfocus_color then unfocus_color = wm.config.border_unfocus end
    self:set_border(wm.config.border_width, unfocus_color, false)

    wm.hooks.fire("window_unfocus", self, self.workspace)
end

function window.Window:map()
    local wm = window.wm
    if not wm then return end
    local X11 = wm.x11
    self.mapped = true
    self.visible = true
    X11.map_window(self.id)
end

function window.Window:unmap()
    local wm = window.wm
    if not wm then return end
    local X11 = wm.x11
    self.mapped = false
    self.visible = false
    X11.unmap_window(self.id)
end

function window.Window:close()
    local wm = window.wm
    if not wm then return end
    local X11 = wm.x11
    self.is_destroying = true

    local wm_delete = X11.intern_atom("WM_DELETE_WINDOW")
    local protocols = X11.get_wm_protocols(self.id)
    local has_delete = false
    for _, p in ipairs(protocols) do
        if p == wm_delete then
            has_delete = true
            break
        end
    end

    if has_delete then
        X11.send_client_message(self.id,
            X11.intern_atom("WM_PROTOCOLS"),
            wm_delete)
    else
        X11.destroy_window(self.id)
    end

    window.unregister(self.id)
end

function window.Window:kill()
    local wm = window.wm
    if not wm then return end
    local X11 = wm.x11
    X11.destroy_window(self.id)
    window.unregister(self.id)
end

function window.Window:toggle_floating()
    self.floating = not self.floating
    if self.floating then
        if not self.float_x then
            self.float_x = self.x
            self.float_y = self.y
            self.float_width = self.width
            self.float_height = self.height
        end
    end
    local ws = window.wm.workspaces:get_current()
    if ws then ws:arrange() end
end

function window.Window:toggle_maximize()
    self.maximized = not self.maximized
    local ws = window.wm.workspaces:get_current()
    if ws then ws:arrange() end
end

function window.Window:toggle_fullscreen()
    self.fullscreen = not self.fullscreen
    local ws = window.wm.workspaces:get_current()
    if ws then ws:arrange() end
end

function window.Window:move_to_workspace(ws_num)
    local wm = window.wm
    if not wm then return end
    local target_ws = wm.workspaces:get_by_index(ws_num)
    if not target_ws then return end

    local old_ws = self.workspace
    if old_ws then
        old_ws:remove_window(self.id)
    end

    target_ws:add_window(self.id)
    self.workspace = target_ws

    if ws_num ~= wm.workspaces.current_ws then
        wm.x11.unmap_window(self.id)
    end

    wm.x11.sync()
    wm.workspaces:sync_ewmh()
    wm.hooks.fire("workspace_switch", target_ws, old_ws)
end

function window.Window:snap_to_grid()
    local ws = self.workspace
    if not ws then return end
    local rect = ws:get_rect()
    local x = self.x
    local y = self.y
    local cfg = window.wm.config
    if cfg and cfg.snap_pixel > 0 then
        local snap = cfg.snap_pixel
        if math.abs(x - rect.x) < snap then x = rect.x end
        if math.abs(y - rect.y) < snap then y = rect.y end
        if math.abs((x + self.width) - (rect.x + rect.width)) < snap then
            x = rect.x + rect.width - self.width
        end
        if math.abs((y + self.height) - (rect.y + rect.height)) < snap then
            y = rect.y + rect.height - self.height
        end
    end
    self:update_geometry(x, y, self.width, self.height)
end

function window.Window:maximize(orientation)
    if orientation == "horizontal" then
        self.maximized_h = true
    elseif orientation == "vertical" then
        self.maximized_v = true
    else
        self.maximized = true
    end
    local ws = window.wm.workspaces:get_current()
    if ws then ws:arrange() end
end

function window.Window:unmaximize(orientation)
    if orientation == "horizontal" then
        self.maximized_h = false
    elseif orientation == "vertical" then
        self.maximized_v = false
    else
        self.maximized = false
    end
    local ws = window.wm.workspaces:get_current()
    if ws then ws:arrange() end
end

function window.Window:fullscreen()
    self.fullscreen = not self.fullscreen
    local ws = window.wm.workspaces:get_current()
    if ws then ws:arrange() end
end

function window.Window:minimize()
    self.minimized = not self.minimized
    if self.minimized then
        self:unmap()
    else
        self:map()
    end
end

function window.Window:raise()
    local wm = window.wm
    if not wm then return end
    wm.x11.raise_window(self.id)
end

function window.Window:lower()
    local wm = window.wm
    if not wm then return end
    wm.x11.lower_window(self.id)
end

function window.Window:make_sticky()
    self.sticky = not self.sticky
    local X11 = window.wm.x11
    local atom = X11.intern_atom("_NET_WM_STATE_STICKY")
    if self.sticky then
        X11.add_wm_state(self.id, atom)
    else
        X11.remove_wm_state(self.id, atom)
    end
end

function window.Window:make_above()
    self.above = not self.above
    local X11 = window.wm.x11
    local atom = X11.intern_atom("_NET_WM_STATE_ABOVE")
    if self.above then
        X11.add_wm_state(self.id, atom)
    else
        X11.remove_wm_state(self.id, atom)
    end
end

function window.Window:make_below()
    self.below = not self.below
    local X11 = window.wm.x11
    local atom = X11.intern_atom("_NET_WM_STATE_BELOW")
    if self.below then
        X11.add_wm_state(self.id, atom)
    else
        X11.remove_wm_state(self.id, atom)
    end
end

function window.Window:set_skip_taskbar(skip)
    self.skip_taskbar = skip
    local X11 = window.wm.x11
    local atom = X11.intern_atom("_NET_WM_STATE_SKIP_TASKBAR")
    if skip then
        X11.add_wm_state(self.id, atom)
    else
        X11.remove_wm_state(self.id, atom)
    end
end

function window.Window:set_skip_pager(skip)
    self.skip_pager = skip
    local X11 = window.wm.x11
    local atom = X11.intern_atom("_NET_WM_STATE_SKIP_PAGER")
    if skip then
        X11.add_wm_state(self.id, atom)
    else
        X11.remove_wm_state(self.id, atom)
    end
end

function window.Window:toggle_always_on_top()
    self.always_on_top = not self.always_on_top
    local X11 = window.wm.x11
    local atom = X11.intern_atom("_NET_WM_STATE_ABOVE")
    if self.always_on_top then
        X11.add_wm_state(self.id, atom)
    else
        X11.remove_wm_state(self.id, atom)
    end
end

function window.register(id)
    local w = window.Window:new(id)
    window.windows[id] = w
    return w
end

function window.unregister(id)
    window.windows[id] = nil
end

function window.get(id)
    return window.windows[id]
end

function window.is_registered(id)
    return window.windows[id] ~= nil
end

function window.all()
    return window.windows
end

function window.count()
    local count = 0
    for _ in pairs(window.windows) do
        count = count + 1
    end
    return count
end

function window.get_visible()
    local result = {}
    for id, w in pairs(window.windows) do
        if w.visible then
            result[#result+1] = w
        end
    end
    return result
end

function window.get_tiled()
    local result = {}
    for id, w in pairs(window.windows) do
        if w.tiled and w.visible and not w.floating and not w.fullscreen then
            result[#result+1] = w
        end
    end
    return result
end

function window.get_floating()
    local result = {}
    for id, w in pairs(window.windows) do
        if w.floating and w.visible then
            result[#result+1] = w
        end
    end
    return result
end

function window.get_fullscreen()
    local result = {}
    for id, w in pairs(window.windows) do
        if w.fullscreen and w.visible then
            result[#result+1] = w
        end
    end
    return result
end

function window.get_focused()
    local ws = window.wm.workspaces:get_current()
    if not ws then return nil end
    if ws.focused then
        return window.windows[ws.focused]
    end
    return nil
end

function window.get_urgent()
    local result = {}
    for id, w in pairs(window.windows) do
        if w.urgent then
            result[#result+1] = w
        end
    end
    return result
end

function window.focus_next()
    local ws = window.wm.workspaces:get_current()
    if ws then ws:focus_next() end
end

function window.focus_prev()
    local ws = window.wm.workspaces:get_current()
    if ws then ws:focus_prev() end
end

function window.focus_direction(dir)
    local ws = window.wm.workspaces:get_current()
    if ws then ws:focus_direction(dir) end
end

function window.move_focused(direction)
    local ws = window.wm.workspaces:get_current()
    if ws then ws:move_focused(direction) end
end

function window.close_focused()
    local ws = window.wm.workspaces:get_current()
    if ws then ws:close_focused() end
end

function window.kill_focused()
    local ws = window.wm.workspaces:get_current()
    if ws then
        local w = ws:get_focused()
        if w then w:kill() end
    end
end

function window.next_layout()
    local ws = window.wm.workspaces:get_current()
    if ws then ws:next_layout() end
end

function window.prev_layout()
    local ws = window.wm.workspaces:get_current()
    if ws then ws:prev_layout() end
end

function window.toggle_floating_focused()
    local ws = window.wm.workspaces:get_current()
    if ws then
        local w = ws:get_focused()
        if w then w:toggle_floating() end
    end
end

function window.maximize_focused()
    local ws = window.wm.workspaces:get_current()
    if ws then
        local w = ws:get_focused()
        if w then w:maximize() end
    end
end

function window.fullscreen_focused()
    local ws = window.wm.workspaces:get_current()
    if ws then
        local w = ws:get_focused()
        if w then w:fullscreen() end
    end
end

function window.swap_master()
    local ws = window.wm.workspaces:get_current()
    if ws then ws:swap_master() end
end

function window.inc_master()
    if window.wm then window.wm:layout_increment(1) end
end

function window.dec_master()
    if window.wm then window.wm:layout_increment(-1) end
end

function window.inc_margin()
    if window.wm then window.wm:layout_increment_margin(1) end
end

function window.dec_margin()
    if window.wm then window.wm:layout_decrement_margin(1) end
end

function window.reload()
    if window.wm then window.wm:reload() end
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
        local ws = window.wm.workspaces:get_current()
        if ws then ws:focus_window(urgent[1].id) end
    end
end

function window.go_back()
    local ws = window.wm.workspaces
    if ws then ws:go_back() end
end

function window.toggle_split()
    if window.wm then window.wm:layout_toggle_split() end
end

function window.layout_info()
    if window.wm then window.wm:layout_info() end
end

return window
