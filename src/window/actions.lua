local registry = require("window.registry")

local actions = {}

function actions.install()
    local Window = registry.Window

    function Window:toggle_floating()
        self.floating = not self.floating
        if self.floating and not self.float_x then
            self.float_x = self.x
            self.float_y = self.y
            self.float_width = self.width
            self.float_height = self.height
        end
        local wm = registry.wm
        if wm and wm.workspaces then
            local ws = wm.workspaces:get_current()
            if ws then ws:arrange() end
        end
    end

    function Window:toggle_maximize()
        self.maximized = not self.maximized
        local wm = registry.wm
        if wm and wm.workspaces then
            local ws = wm.workspaces:get_current()
            if ws then ws:arrange() end
        end
    end

    function Window:toggle_fullscreen()
        self.fullscreen = not self.fullscreen
        local wm = registry.wm
        if wm and wm.workspaces then
            local ws = wm.workspaces:get_current()
            if ws then ws:arrange() end
        end
    end

    function Window:move_to_workspace(ws_num)
        local wm = registry.wm
        if not wm or not wm.workspaces then return end
        local target_ws = wm.workspaces:get_by_index(ws_num)
        if not target_ws then return end
        local old_ws = self.workspace
        if old_ws then old_ws:remove_window(self.id) end
        target_ws:add_window(self.id)
        self.workspace = target_ws
        if ws_num ~= wm.workspaces.current_ws then
            wm.x11.unmap_window(self.id)
        end
        wm.x11.sync()
        wm.workspaces:sync_ewmh()
        wm.hooks.fire("workspace_switch", target_ws, old_ws)
    end

    function Window:snap_to_grid()
        local ws = self.workspace
        if not ws then return end
        local rect = ws:get_rect()
        local x, y = self.x, self.y
        local cfg = registry.wm.config
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

    function Window:maximize(orientation)
        if orientation == "horizontal" then self.maximized_h = true
        elseif orientation == "vertical" then self.maximized_v = true
        else self.maximized = true end
        local wm = registry.wm
        if wm and wm.workspaces then
            local ws = wm.workspaces:get_current()
            if ws then ws:arrange() end
        end
    end

    function Window:unmaximize(orientation)
        if orientation == "horizontal" then self.maximized_h = false
        elseif orientation == "vertical" then self.maximized_v = false
        else self.maximized = false end
        local wm = registry.wm
        if wm and wm.workspaces then
            local ws = wm.workspaces:get_current()
            if ws then ws:arrange() end
        end
    end

    function Window:minimize()
        self.minimized = not self.minimized
        if self.minimized then self:unmap() else self:map() end
    end

    function Window:raise()
        local wm = registry.wm
        if wm then wm.x11.raise_window(self.id) end
    end

    function Window:lower()
        local wm = registry.wm
        if wm then wm.x11.lower_window(self.id) end
    end

    function Window:make_sticky()
        self.sticky = not self.sticky
        local X11 = registry.wm.x11
        local atom = X11.intern_atom("_NET_WM_STATE_STICKY")
        if self.sticky then X11.add_wm_state(self.id, atom)
        else X11.remove_wm_state(self.id, atom) end
    end

    function Window:make_above()
        self.above = not self.above
        local X11 = registry.wm.x11
        local atom = X11.intern_atom("_NET_WM_STATE_ABOVE")
        if self.above then X11.add_wm_state(self.id, atom)
        else X11.remove_wm_state(self.id, atom) end
    end

    function Window:make_below()
        self.below = not self.below
        local X11 = registry.wm.x11
        local atom = X11.intern_atom("_NET_WM_STATE_BELOW")
        if self.below then X11.add_wm_state(self.id, atom)
        else X11.remove_wm_state(self.id, atom) end
    end

    function Window:set_skip_taskbar(skip)
        self.skip_taskbar = skip
        local X11 = registry.wm.x11
        local atom = X11.intern_atom("_NET_WM_STATE_SKIP_TASKBAR")
        if skip then X11.add_wm_state(self.id, atom)
        else X11.remove_wm_state(self.id, atom) end
    end

    function Window:set_skip_pager(skip)
        self.skip_pager = skip
        local X11 = registry.wm.x11
        local atom = X11.intern_atom("_NET_WM_STATE_SKIP_PAGER")
        if skip then X11.add_wm_state(self.id, atom)
        else X11.remove_wm_state(self.id, atom) end
    end

    function Window:toggle_always_on_top()
        self.always_on_top = not self.always_on_top
        local X11 = registry.wm.x11
        local atom = X11.intern_atom("_NET_WM_STATE_ABOVE")
        if self.always_on_top then X11.add_wm_state(self.id, atom)
        else X11.remove_wm_state(self.id, atom) end
    end
end

return actions