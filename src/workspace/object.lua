local debug = require("debug")

local object = {}

object.Workspace = {}
object.Workspace.__index = object.Workspace

function object.Workspace:new(index, name, rect, monitor)
    local ws = setmetatable({}, object.Workspace)
    ws.index = index
    ws.name = name or tostring(index)
    ws.x = rect and rect.x or 0
    ws.y = rect and rect.y or 0
    ws.width = rect and rect.width or 1920
    ws.height = rect and rect.height or 1080
    ws.windows = {}
    ws.focused = nil
    ws.focus_history = {}
    ws.master_count = 1
    ws.master_ratio = 0.5
    ws.layout = "master-stack"
    ws.layout_index = 1
    ws.monitor = monitor
    ws.is_visible = true
    ws.is_dirty = true
    ws.arrange_pending = false
    ws.window_stack = {}
    return ws
end

function object.Workspace:get_rect()
    return { x = self.x, y = self.y, width = self.width, height = self.height }
end

function object.Workspace:add_window(id)
    for _, wid in ipairs(self.windows) do
        if wid == id then return end
    end
    self.windows[#self.windows + 1] = id
    self.window_stack[#self.window_stack + 1] = id
    self:mark_dirty()
end

function object.Workspace:remove_window(id)
    for i, wid in ipairs(self.windows) do
        if wid == id then table.remove(self.windows, i) break end
    end
    for i, wid in ipairs(self.window_stack) do
        if wid == id then table.remove(self.window_stack, i) break end
    end
    if self.focused == id then
        self.focused = nil
        self:refocus()
    end
    self:mark_dirty()
end

function object.Workspace:raise_window(id)
    for i, wid in ipairs(self.window_stack) do
        if wid == id then
            table.remove(self.window_stack, i)
            self.window_stack[#self.window_stack + 1] = id
            break
        end
    end
end

function object.Workspace:mark_dirty()
    self.is_dirty = true
    self.arrange_pending = true
end

function object.Workspace:clear_dirty()
    self.is_dirty = false
    self.arrange_pending = false
end

function object.Workspace:set_layout(layout_name)
    self.layout = layout_name
    local wm = self._wm
    if wm and wm.layouts then
        local names = wm.layouts.list_layout_names()
        for i, name in ipairs(names) do
            if name == layout_name then self.layout_index = i break end
        end
    end
    self:mark_dirty()
end

function object.Workspace:next_layout()
    local wm = self._wm
    if not wm or not wm.layouts then return end
    local names = wm.layouts.list_layout_names()
    self.layout_index = self.layout_index + 1
    if self.layout_index > #names then self.layout_index = 1 end
    self.layout = names[self.layout_index]
    self:mark_dirty()
end

function object.Workspace:prev_layout()
    local wm = self._wm
    if not wm or not wm.layouts then return end
    local names = wm.layouts.list_layout_names()
    self.layout_index = self.layout_index - 1
    if self.layout_index < 1 then self.layout_index = #names end
    self.layout = names[self.layout_index]
    self:mark_dirty()
end

function object.Workspace:arrange()
    local wm = self._wm
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
            if w.fullscreen then table.insert(fullscreen_windows, w)
            elseif w.floating then table.insert(floating_windows, w)
            else table.insert(tiled_windows, w) w.tiled = true end
        end
    end

    if #fullscreen_windows > 0 then
        for _, w in ipairs(fullscreen_windows) do
            w:update_geometry(self.x, self.y, self.width, self.height)
            X11.move_resize_window(w.id, self.x, self.y, self.width, self.height)
        end
        for _, w in ipairs(tiled_windows) do w:raise() end
        return
    end

    local layout_cfg = setmetatable({
        master_count = self.master_count,
        master_ratio = self.master_ratio,
        gap_size = wm.gap_size or config.gap_size or 0,
        border_width = config.border_width or 0,
    }, {__index = config})

    layout_mgr.arrange(self.layout, tiled_windows, {
        x = self.x, y = self.y, width = self.width, height = self.height,
    }, layout_cfg)

    for _, w in ipairs(floating_windows) do
        if w.float_x and w.float_y and w.float_width and w.float_height then
            X11.move_resize_window(w.id, w.float_x, w.float_y, w.float_width, w.float_height)
        end
    end

    self:clear_dirty()
end

function object.Workspace:focus_window(id)
    local wm = self._wm
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

function object.Workspace:save_focus_history()
    if self.focused then
        for i = #self.focus_history, 1, -1 do
            if self.focus_history[i] == self.focused then
                table.remove(self.focus_history, i) break
            end
        end
        table.insert(self.focus_history, self.focused)
        if #self.focus_history > 10 then table.remove(self.focus_history, 1) end
    end
end

function object.Workspace:get_focused()
    if self.focused then return self._wm.windows.get(self.focused) end
    return nil
end

function object.Workspace:focus_next()
    if #self.windows == 0 then return end
    local idx = nil
    if self.focused then
        for i, wid in ipairs(self.windows) do
            if wid == self.focused then idx = i break end
        end
    end
    local next_idx = idx and idx + 1 or 1
    if next_idx > #self.windows then next_idx = 1 end
    local wid = self.windows[next_idx]
    if wid then self:focus_window(wid) end
end

function object.Workspace:focus_prev()
    if #self.windows == 0 then return end
    local idx = nil
    if self.focused then
        for i, wid in ipairs(self.windows) do
            if wid == self.focused then idx = i break end
        end
    end
    local prev_idx = idx and idx - 1 or #self.windows
    if prev_idx < 1 then prev_idx = #self.windows end
    local wid = self.windows[prev_idx]
    if wid then self:focus_window(wid) end
end

function object.Workspace:focus_direction(dir)
    if #self.windows == 0 then return end
    local focused_w = self:get_focused()
    if not focused_w then self:focus_next() return end
    local best_w, best_dist = nil, nil
    local fx = focused_w.x + focused_w.width / 2
    local fy = focused_w.y + focused_w.height / 2
    for _, wid in ipairs(self.windows) do
        local w = self._wm.windows.get(wid)
        if w and w.visible and wid ~= self.focused then
            local wx = w.x + w.width / 2
            local wy = w.y + w.height / 2
            local dist, valid = 0, false
            if dir == "left" then if wx < fx then dist = fx - wx; valid = (wy > w.y and wy < w.y + w.height) end
            elseif dir == "right" then if wx > fx then dist = wx - fx; valid = (wy > w.y and wy < w.y + w.height) end
            elseif dir == "up" then if wy < fy then dist = fy - wy; valid = (wx > w.x and wx < w.x + w.width) end
            elseif dir == "down" then if wy > fy then dist = wy - fy; valid = (wx > w.x and wx < w.x + w.width) end
            end
            if valid and (not best_dist or dist < best_dist) then best_dist = dist best_w = w end
        end
    end
    if best_w then self:focus_window(best_w.id) end
end

function object.Workspace:move_focused(direction)
    if not self.focused then return end
    local idx = nil
    for i, wid in ipairs(self.windows) do
        if wid == self.focused then idx = i break end
    end
    if not idx then return end
    local new_idx
    if direction == "left" or direction == "up" then new_idx = idx - 1 if new_idx < 1 then new_idx = #self.windows end
    else new_idx = idx + 1 if new_idx > #self.windows then new_idx = 1 end end
    if new_idx ~= idx then
        self.windows[idx], self.windows[new_idx] = self.windows[new_idx], self.windows[idx]
        self._wm.hooks.fire("layout_change", self, self.layout)
        self:arrange()
    end
end

function object.Workspace:close_focused()
    if self.focused then
        local w = self._wm.windows.get(self.focused)
        if w then w:close() end
    end
end

function object.Workspace:swap_master()
    if not self.focused or #self.windows <= 1 then return end
    for i, wid in ipairs(self.windows) do
        if wid == self.focused and i > 1 then
            self.windows[1], self.windows[i] = self.windows[i], self.windows[1]
            self:arrange() break
        end
    end
end

function object.Workspace:refocus()
    if #self.focus_history > 0 then
        local wid = self.focus_history[#self.focus_history]
        local w = self._wm.windows.get(wid)
        if w and w.visible then self:focus_window(wid) return end
    end
    for i = #self.windows, 1, -1 do
        local wid = self.windows[i]
        local w = self._wm.windows.get(wid)
        if w and w.visible then self:focus_window(wid) return end
    end
end

function object.Workspace:toggle_visibility()
    self.is_visible = not self.is_visible
    if self.is_visible then self:arrange() end
end

return object