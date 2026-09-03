local workspace = {}

workspace.wm = nil
workspace.current_ws = 1

function workspace.set_wm(wm)
    workspace.wm = wm
end

workspace.Workspace = {}
workspace.Workspace.__index = workspace.Workspace
workspace.WorkspaceManager = {}
workspace.WorkspaceManager.__index = workspace.WorkspaceManager

function workspace.Workspace:new(index, name, rect, monitor)
    local ws = setmetatable({}, workspace.Workspace)
    ws.index = index
    ws.name = name or tostring(index)
    ws.x = rect and rect.x or 0
    ws.y = rect and rect.y or 0
    ws.width = rect and rect.width or 1920
    ws.height = rect and rect.height or 1080
    ws.windows = {}
    ws.focused = nil
    ws.focus_history = {}
    ws.master = nil
    ws.master_count = 1
    ws.master_ratio = 0.5
    ws.layout = "master-stack"
    ws.layout_index = 1
    ws.monitor = monitor
    ws.is_visible = true
    ws.opacity = 1.0
    ws.bg_color = nil
    ws.is_dirty = true
    ws.arrange_pending = false
    ws.window_stack = {}
    ws.dragging = false
    ws.resizing = false
    ws.drag_window = nil
    ws.resize_window = nil
    ws.resize_grip = nil
    ws.drag_x = 0
    ws.drag_y = 0
    ws.resize_start_x = 0
    ws.resize_start_y = 0
    ws.resize_start_w = 0
    ws.resize_start_h = 0
    return ws
end

function workspace.Workspace:get_rect()
    return {
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height,
    }
end

function workspace.Workspace:add_window(id)
    for _, wid in ipairs(self.windows) do
        if wid == id then return end
    end
    self.windows[#self.windows + 1] = id
    self.window_stack[#self.window_stack + 1] = id
    self:mark_dirty()
end

function workspace.Workspace:remove_window(id)
    for i, wid in ipairs(self.windows) do
        if wid == id then
            table.remove(self.windows, i)
            break
        end
    end
    for i, wid in ipairs(self.window_stack) do
        if wid == id then
            table.remove(self.window_stack, i)
            break
        end
    end
    if self.focused == id then
        self.focused = nil
        self:refocus()
    end
    self:mark_dirty()
end

function workspace.Workspace:raise_window(id)
    for i, wid in ipairs(self.window_stack) do
        if wid == id then
            table.remove(self.window_stack, i)
            self.window_stack[#self.window_stack + 1] = id
            break
        end
    end
end

function workspace.Workspace:mark_dirty()
    self.is_dirty = true
    self.arrange_pending = true
end

function workspace.Workspace:clear_dirty()
    self.is_dirty = false
    self.arrange_pending = false
end

function workspace.Workspace:set_layout(layout_name)
    self.layout = layout_name
    local layouts = workspace.wm.layouts
    if layouts then
        local names = layouts.list_layout_names()
        for i, name in ipairs(names) do
            if name == layout_name then
                self.layout_index = i
                break
            end
        end
    end
    self:mark_dirty()
end

function workspace.Workspace:next_layout()
    local layouts = workspace.wm.layouts
    if not layouts then return end
    local names = layouts.list_layout_names()
    self.layout_index = self.layout_index + 1
    if self.layout_index > #names then
        self.layout_index = 1
    end
    self.layout = names[self.layout_index]
    self:mark_dirty()
end

function workspace.Workspace:prev_layout()
    local layouts = workspace.wm.layouts
    if not layouts then return end
    local names = layouts.list_layout_names()
    self.layout_index = self.layout_index - 1
    if self.layout_index < 1 then
        self.layout_index = #names
    end
    self.layout = names[self.layout_index]
    self:mark_dirty()
end

function workspace.Workspace:arrange()
    local wm = workspace.wm
    if not wm then return end
    local wnd = wm.windows
    local X11 = wm.x11
    local config = wm.config
    local layout_mgr = wm.layouts
    if not layout_mgr then return end

    local tiled_windows = {}
    local floating_windows = {}
    local fullscreen_windows = {}

    for _, wid in ipairs(self.windows) do
        local w = wnd.get(wid)
        if w and w.visible then
            if w.fullscreen then
                table.insert(fullscreen_windows, w)
            elseif w.floating then
                table.insert(floating_windows, w)
            else
                table.insert(tiled_windows, w)
                w.tiled = true
            end
        end
    end

    if #fullscreen_windows > 0 then
        for _, w in ipairs(fullscreen_windows) do
            if w then
                w:update_geometry(self.x, self.y, self.width, self.height)
                X11.move_resize_window(w.id, self.x, self.y, self.width, self.height)
            end
        end
        for _, w in ipairs(tiled_windows) do
            if w then w:raise() end
        end
        return
    end

    local layout_cfg = setmetatable({
        master_count = self.master_count,
        master_ratio = self.master_ratio,
        gap_size = wm.gap_size or config.gap_size or 0,
        border_width = config.border_width or 0,
    }, {__index = config})

    local layout = layout_mgr.get_layout(self.layout)
    if layout and layout.arrange then
        layout.arrange(tiled_windows, {
            x = self.x,
            y = self.y,
            width = self.width,
            height = self.height,
        }, layout_cfg)
    end

    for _, w in ipairs(floating_windows) do
        if w.float_x and w.float_y and w.float_width and w.float_height then
            X11.move_resize_window(w.id, w.float_x, w.float_y,
                w.float_width, w.float_height)
        end
    end

    self:clear_dirty()
end

function workspace.Workspace:focus_window(id)
    local wm = workspace.wm
    if not wm then return end
    local w = wm.windows.get(id)
    if not w then return end
    local prev_focused = self.focused
    if prev_focused and prev_focused ~= id then
        local pw = wm.windows.get(prev_focused)
        if pw then pw:unfocus() end
    end
    self.focused = id
    w:focus()
    w:raise()
    self:save_focus_history()
    wm.hooks.fire("window_focus", w, self)
end

function workspace.Workspace:save_focus_history()
    if self.focused then
        for i = #self.focus_history, 1, -1 do
            if self.focus_history[i] == self.focused then
                table.remove(self.focus_history, i)
                break
            end
        end
        table.insert(self.focus_history, self.focused)
        if #self.focus_history > 10 then
            table.remove(self.focus_history, 1)
        end
    end
end

function workspace.Workspace:get_focused()
    if self.focused then
        return workspace.wm.windows.get(self.focused)
    end
    return nil
end

function workspace.Workspace:focus_next()
    if #self.windows == 0 then return end
    local idx = nil
    if self.focused then
        for i, wid in ipairs(self.windows) do
            if wid == self.focused then
                idx = i
                break
            end
        end
    end
    local next_idx = idx
    if idx then
        next_idx = idx + 1
        if next_idx > #self.windows then next_idx = 1 end
    else
        next_idx = 1
    end
    local wid = self.windows[next_idx]
    if wid then self:focus_window(wid) end
end

function workspace.Workspace:focus_prev()
    if #self.windows == 0 then return end
    local idx = nil
    if self.focused then
        for i, wid in ipairs(self.windows) do
            if wid == self.focused then
                idx = i
                break
            end
        end
    end
    local prev_idx
    if idx then
        prev_idx = idx - 1
        if prev_idx < 1 then prev_idx = #self.windows end
    else
        prev_idx = #self.windows
    end
    local wid = self.windows[prev_idx]
    if wid then self:focus_window(wid) end
end

function workspace.Workspace:focus_direction(dir)
    if #self.windows == 0 then return end
    local focused_w = self:get_focused()
    if not focused_w then
        self:focus_next()
        return
    end

    local best_w = nil
    local best_dist = nil
    local fx, fy = focused_w.x + focused_w.width / 2,
                   focused_w.y + focused_w.height / 2

    for _, wid in ipairs(self.windows) do
        local w = workspace.wm.windows.get(wid)
        if w and w.visible and wid ~= self.focused then
            local wx, wy = w.x + w.width / 2,
                           w.y + w.height / 2
            local dist, valid = 0, false
            if dir == "left" then
                if wx < fx then dist = fx - wx; valid = (wy > w.y and wy < w.y + w.height) end
            elseif dir == "right" then
                if wx > fx then dist = wx - fx; valid = (wy > w.y and wy < w.y + w.height) end
            elseif dir == "up" then
                if wy < fy then dist = fy - wy; valid = (wx > w.x and wx < w.x + w.width) end
            elseif dir == "down" then
                if wy > fy then dist = wy - fy; valid = (wx > w.x and wx < w.x + w.width) end
            end

            if valid then
                if not best_dist or dist < best_dist then
                    best_dist = dist
                    best_w = w
                end
            end
        end
    end

    if best_w then
        self:focus_window(best_w.id)
    end
end

function workspace.Workspace:move_focused(direction)
    if not self.focused then return end
    local idx = nil
    for i, wid in ipairs(self.windows) do
        if wid == self.focused then
            idx = i
            break
        end
    end

    local new_idx
    if idx then
        if direction == "left" or direction == "up" then
            new_idx = idx - 1
            if new_idx < 1 then new_idx = #self.windows end
        else
            new_idx = idx + 1
            if new_idx > #self.windows then new_idx = 1 end
        end
    end

    if new_idx and new_idx ~= idx then
        self.windows[idx], self.windows[new_idx] = self.windows[new_idx], self.windows[idx]
        workspace.wm.hooks.fire("layout_change", self, self.layout)
        self:arrange()
    end
end

function workspace.Workspace:close_focused()
    if self.focused then
        local w = workspace.wm.windows.get(self.focused)
        if w then w:close() end
    end
end

function workspace.Workspace:swap_master()
    if not self.focused or #self.windows <= 1 then return end
    for i, wid in ipairs(self.windows) do
        if wid == self.focused and i > 1 then
            self.windows[1], self.windows[i] = self.windows[i], self.windows[1]
            self:arrange()
            break
        end
    end
end

function workspace.Workspace:refocus()
    if #self.focus_history > 0 then
        local wid = self.focus_history[#self.focus_history]
        local w = workspace.wm.windows.get(wid)
        if w and w.visible then
            self:focus_window(wid)
            return
        end
    end

    for i = #self.windows, 1, -1 do
        local wid = self.windows[i]
        local w = workspace.wm.windows.get(wid)
        if w and w.visible then
            self:focus_window(wid)
            return
        end
    end
end

function workspace.Workspace:toggle_visibility()
    self.is_visible = not self.is_visible
    if self.is_visible then
        self:arrange()
    end
end

function workspace.WorkspaceManager:new(wm)
    local mgr = setmetatable({}, workspace.WorkspaceManager)
    mgr.wm = wm
    mgr.workspaces = {}
    mgr.current_ws = 1
    mgr.history = {}
    mgr.scroll_active = false
    mgr.scroll_time = 0
    mgr.scroll_duration = 250
    mgr.scroll_offset = 0
    mgr.scroll_target = 0
    mgr.scroll_animate = false
    return mgr
end

function workspace.WorkspaceManager:init()
    local config = self.wm.config
    local wm = self.wm

    local screens
    if wm.x11.xinerama_is_active() then
        screens = wm.x11.xinerama_query_screens()
    else
        screens = {wm.x11.get_screen_rect()}
    end

    local workspace_count = config.workspaces.count

    for i = 1, workspace_count do
        local screen_idx = ((i - 1) % #screens) + 1
        local screen = screens[screen_idx]
        local ws_name = config.workspaces.names[i] or tostring(i)
        local ws = workspace.Workspace:new(i, ws_name, screen, screen_idx)
        self.workspaces[i] = ws
    end

    self.current_ws = 1

    for i = 2, workspace_count do
        self.workspaces[i].is_visible = false
    end

    local layout_names = wm.layouts.list_layout_names()
    for _, ws in ipairs(self.workspaces) do
        ws.layout = layout_names[1] or "master-stack"
        ws.layout_index = 1
    end

    self:update_desktop_names()
    self:sync_ewmh()
    self:arrange_all()
end

function workspace.WorkspaceManager:arrange_all()
    for _, ws in ipairs(self.workspaces) do
        if ws then
            ws:arrange()
        end
    end
end

function workspace.WorkspaceManager:switch_to(ws_num)
    if ws_num < 1 or ws_num > #self.workspaces then return end
    if ws_num == self.current_ws then return end

    local wm = self.wm
    local old_ws = self.workspaces[self.current_ws]
    local new_ws = self.workspaces[ws_num]

    if not new_ws then return end

    table.insert(self.history, self.current_ws)
    if #self.history > 10 then
        table.remove(self.history, 1)
    end

    if old_ws then
        for _, wid in ipairs(old_ws.windows) do
            if wid then
                wm.x11.unmap_window(wid)
            end
        end
        old_ws.is_visible = false
    end

    self.current_ws = ws_num
    new_ws.is_visible = true

    for _, wid in ipairs(new_ws.windows) do
        if wid then
            wm.x11.map_window(wid)
        end
    end

    new_ws:arrange()

    if new_ws.focused then
        local w = wm.windows.get(new_ws.focused)
        if w then w:focus() end
    else
        new_ws:refocus()
    end

    self:sync_ewmh()
    wm.hooks.fire("workspace_switch", new_ws, old_ws)
end

function workspace.WorkspaceManager:scroll_workspaces(direction)
    local config = self.wm.config
    local ws_cfg = config.workspace_behavior or {}

    local new_ws
    if direction == "up" or direction == "right" then
        new_ws = self.current_ws + 1
    elseif direction == "down" or direction == "left" then
        new_ws = self.current_ws - 1
    end

    if new_ws > #self.workspaces then
        if ws_cfg.wrap_workspaces then
            new_ws = 1
        else
            return
        end
    elseif new_ws < 1 then
        if ws_cfg.wrap_workspaces then
            new_ws = #self.workspaces
        else
            return
        end
    end

    self.scroll_offset = 0
    self.scroll_active = ws_cfg.scroll_animate
    self.scroll_time = 0
    self.scroll_duration = ws_cfg.scroll_animation_time or 250

    self:switch_to(new_ws)
end

function workspace.WorkspaceManager:switch_to_name(name)
    for i, ws in ipairs(self.workspaces) do
        if ws.name == name then
            self:switch_to(i)
            return true
        end
    end
    return false
end

function workspace.WorkspaceManager:move_window_to_workspace(wid, ws_num)
    if ws_num < 1 or ws_num > #self.workspaces then return end

    local wm = self.wm
    local w = wm.windows.get(wid)
    if not w then return end

    local target_ws = self.workspaces[ws_num]
    if not target_ws then return end

    for i, wid2 in ipairs(self.workspaces[self.current_ws].windows) do
        if wid2 == wid then
            table.remove(self.workspaces[self.current_ws].windows, i)
            break
        end
    end

    if w.workspace then
        w.workspace:remove_window(wid)
    end

    target_ws:add_window(wid)
    w.workspace = target_ws

    if ws_num ~= self.current_ws then
        wm.x11.unmap_window(wid)
    end

    self:sync_ewmh()
    wm.hooks.fire("workspace_switch", target_ws, self.workspaces[self.current_ws])
end

function workspace.WorkspaceManager:go_back()
    if #self.history == 0 then return end
    local prev = self.history[#self.history]
    table.remove(self.history)
    self:switch_to(prev)
end

function workspace.WorkspaceManager:get_current()
    return self.workspaces[self.current_ws]
end

function workspace.WorkspaceManager:get_by_index(idx)
    return self.workspaces[idx]
end

function workspace.WorkspaceManager:get_all()
    return self.workspaces
end

function workspace.WorkspaceManager:sync_ewmh()
    local wm = self.wm
    local X11 = wm.x11

    X11.set_current_desktop(self.current_ws - 1)

    local client_list = {}
    for _, ws in ipairs(self.workspaces) do
        for _, wid in ipairs(ws.windows) do
            table.insert(client_list, wid)
        end
    end

    if #client_list > 0 then
        X11.set_client_list(client_list)

        local stacking = {}
        for _, ws in ipairs(self.workspaces) do
            if ws.is_visible then
                for i = #ws.window_stack, 1, -1 do
                    local wid = ws.window_stack[i]
                    if wid then
                        table.insert(stacking, wid)
                    end
                end
            end
        end

        if #stacking > 0 then
            X11.set_client_list_stacking(stacking)
        end
    end

    local current = self.workspaces[self.current_ws]
    if current and current.focused then
        X11.set_active_window(current.focused)
    end

    local rects = {}
    for _, ws in ipairs(self.workspaces) do
        rects[#rects+1] = {
            x = ws.x, y = ws.y,
            width = ws.width, height = ws.height
        }
    end
    X11.set_workarea(rects)
end

function workspace.WorkspaceManager:update_desktop_names()
    local names = {}
    for _, ws in ipairs(self.workspaces) do
        names[#names+1] = ws.name
    end
    self.wm.x11.set_desktop_names(names)
end

function workspace.WorkspaceManager:set_workspace_count(count)
    while #self.workspaces < count do
        local last_ws = self.workspaces[#self.workspaces]
        local screen = {x = 0, y = 0, width = 1920, height = 1080}
        if last_ws then
            screen = {
                x = last_ws.x, y = last_ws.y,
                width = last_ws.width, height = last_ws.height
            }
        end
        local ws_name = self.wm.config.workspaces.names[#self.workspaces + 1] or tostring(#self.workspaces + 1)
        local ws = workspace.Workspace:new(#self.workspaces + 1, ws_name, screen)
        self.workspaces[#self.workspaces + 1] = ws
    end

    while #self.workspaces > count do
        table.remove(self.workspaces)
    end

    self:sync_ewmh()
    self:update_desktop_names()
end

return workspace
