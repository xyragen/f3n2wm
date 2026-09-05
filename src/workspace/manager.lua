local debug = require("debug")

local manager = {}

manager.WorkspaceManager = {}
manager.WorkspaceManager.__index = manager.WorkspaceManager

function manager.WorkspaceManager:new(wm)
    local mgr = setmetatable({}, manager.WorkspaceManager)
    mgr.wm = wm
    mgr.workspaces = {}
    mgr.current_ws = 1
    mgr.history = {}
    return mgr
end

function manager.WorkspaceManager:set_workspace_refs()
    for _, ws in ipairs(self.workspaces) do
        ws._wm = self.wm
    end
end

function manager.WorkspaceManager:init()
    local config = self.wm.config
    local wm = self.wm

    local screens
    if wm.x11.xinerama_is_active() then
        screens = wm.x11.xinerama_query_screens()
    else
        screens = {wm.x11.get_screen_rect()}
    end

    local workspace_count = config.workspaces.count
    local Workspace = require("workspace.object").Workspace

    for i = 1, workspace_count do
        local screen_idx = ((i - 1) % #screens) + 1
        local screen = screens[screen_idx]
        local ws_name = config.workspaces.names[i] or tostring(i)
        local ws = Workspace:new(i, ws_name, screen, screen_idx)
        ws._wm = wm
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

function manager.WorkspaceManager:arrange_all()
    for _, ws in ipairs(self.workspaces) do
        if ws then ws:arrange() end
    end
end

function manager.WorkspaceManager:switch_to(ws_num)
    if ws_num < 1 or ws_num > #self.workspaces then return end
    if ws_num == self.current_ws then return end

    local wm = self.wm
    local old_ws = self.workspaces[self.current_ws]
    local new_ws = self.workspaces[ws_num]
    if not new_ws then return end

    table.insert(self.history, self.current_ws)
    if #self.history > 10 then table.remove(self.history, 1) end

    if old_ws then
        for _, wid in ipairs(old_ws.windows) do
            if wid then wm.x11.unmap_window(wid) end
        end
        old_ws.is_visible = false
    end

    self.current_ws = ws_num
    new_ws.is_visible = true

    for _, wid in ipairs(new_ws.windows) do
        if wid then wm.x11.map_window(wid) end
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

function manager.WorkspaceManager:scroll_workspaces(direction)
    local config = self.wm.config
    local ws_cfg = config.workspace_behavior or {}

    local new_ws
    if direction == "up" or direction == "right" then new_ws = self.current_ws + 1
    elseif direction == "down" or direction == "left" then new_ws = self.current_ws - 1 end

    if new_ws > #self.workspaces then
        if ws_cfg.wrap_workspaces then new_ws = 1 else return end
    elseif new_ws < 1 then
        if ws_cfg.wrap_workspaces then new_ws = #self.workspaces else return end
    end

    self:switch_to(new_ws)
end

function manager.WorkspaceManager:switch_to_name(name)
    for i, ws in ipairs(self.workspaces) do
        if ws.name == name then self:switch_to(i) return true end
    end
    return false
end

function manager.WorkspaceManager:move_window_to_workspace(wid, ws_num)
    if ws_num < 1 or ws_num > #self.workspaces then return end
    local wm = self.wm
    local w = wm.windows.get(wid)
    if not w then return end
    local target_ws = self.workspaces[ws_num]
    if not target_ws then return end

    for i, wid2 in ipairs(self.workspaces[self.current_ws].windows) do
        if wid2 == wid then table.remove(self.workspaces[self.current_ws].windows, i) break end
    end
    if w.workspace then w.workspace:remove_window(wid) end
    target_ws:add_window(wid)
    w.workspace = target_ws
    if ws_num ~= self.current_ws then wm.x11.unmap_window(wid) end
    self:sync_ewmh()
    wm.hooks.fire("workspace_switch", target_ws, self.workspaces[self.current_ws])
end

function manager.WorkspaceManager:go_back()
    if #self.history == 0 then return end
    local prev = self.history[#self.history]
    table.remove(self.history)
    self:switch_to(prev)
end

function manager.WorkspaceManager:get_current()
    return self.workspaces[self.current_ws]
end

function manager.WorkspaceManager:get_by_index(idx)
    return self.workspaces[idx]
end

function manager.WorkspaceManager:get_all()
    return self.workspaces
end

function manager.WorkspaceManager:sync_ewmh()
    local wm = self.wm
    local X11 = wm.x11
    X11.set_current_desktop(self.current_ws - 1)

    local client_list = {}
    for _, ws in ipairs(self.workspaces) do
        for _, wid in ipairs(ws.windows) do table.insert(client_list, wid) end
    end

    if #client_list > 0 then
        X11.set_client_list(client_list)
        local stacking = {}
        for _, ws in ipairs(self.workspaces) do
            if ws.is_visible then
                for i = #ws.window_stack, 1, -1 do
                    local wid = ws.window_stack[i]
                    if wid then table.insert(stacking, wid) end
                end
            end
        end
        if #stacking > 0 then X11.set_client_list_stacking(stacking) end
    end

    local current = self.workspaces[self.current_ws]
    if current and current.focused then X11.set_active_window(current.focused) end

    local rects = {}
    for _, ws in ipairs(self.workspaces) do
        rects[#rects+1] = { x = ws.x, y = ws.y, width = ws.width, height = ws.height }
    end
    X11.set_workarea(rects)
end

function manager.WorkspaceManager:update_desktop_names()
    local names = {}
    for _, ws in ipairs(self.workspaces) do names[#names+1] = ws.name end
    self.wm.x11.set_desktop_names(names)
end

function manager.WorkspaceManager:set_workspace_count(count)
    local Workspace = require("workspace.object").Workspace
    while #self.workspaces < count do
        local last_ws = self.workspaces[#self.workspaces]
        local screen = last_ws and { x = last_ws.x, y = last_ws.y, width = last_ws.width, height = last_ws.height } or { x = 0, y = 0, width = 1920, height = 1080 }
        local ws_name = self.wm.config.workspaces.names[#self.workspaces + 1] or tostring(#self.workspaces + 1)
        local ws = Workspace:new(#self.workspaces + 1, ws_name, screen)
        ws._wm = self.wm
        self.workspaces[#self.workspaces + 1] = ws
    end
    while #self.workspaces > count do table.remove(self.workspaces) end
    self:sync_ewmh()
    self:update_desktop_names()
end

return manager