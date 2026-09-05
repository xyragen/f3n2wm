local layout = require("layout")
local window = require("window")

local commands = {}

function commands.install(wm)
    function wm:execute_command(command, event)
        if not command or #command == 0 then return false end
        local parts = {}
        for part in command:gmatch("([^:]+)") do
            parts[#parts+1] = part
        end
        local category = parts[1]
        local action = parts[2] or ""
        local params = {}
        for i = 3, #parts do params[i-2] = parts[i] end

        local w = window.get_focused()
        local ws = self.workspaces and self.workspaces:get_current()

        if category == "spawn" then
            local cmd = table.concat(parts, ":", 2)
            if cmd and #cmd > 0 then
                os.execute(cmd .. " &")
            end
        elseif category == "focus" then
            if action == "left" then window.focus_direction("left")
            elseif action == "right" then window.focus_direction("right")
            elseif action == "up" then window.focus_direction("up")
            elseif action == "down" then window.focus_direction("down")
            elseif action == "prev" then window.focus_prev()
            elseif action == "next" then window.focus_next()
            elseif action == "urgent" then window.focus_urgent()
            end
        elseif category == "move" then
            window.move_focused(action)
        elseif category == "resize" then
            if ws then
                if action == "left" or action == "up" then
                    ws.master_ratio = math.max(0.1, ws.master_ratio - 0.05)
                else
                    ws.master_ratio = math.min(0.9, ws.master_ratio + 0.05)
                end
                ws:arrange()
            end
        elseif category == "window" then
            if action == "close" then
                if w then w:close() end
            elseif action == "kill" then
                if w then w:kill() end
            elseif action == "maximize" then
                if w then
                    if params[1] == "horizontal" then w.maximized_h = not w.maximized_h
                    elseif params[1] == "vertical" then w.maximized_v = not w.maximized_v
                    else w.maximized = not w.maximized end
                    if ws then ws:arrange() end
                end
            elseif action == "fullscreen" then
                if w then w.fullscreen = not w.fullscreen
                if ws then ws:arrange() end end
            elseif action == "toggle_floating" then
                if w then w:toggle_floating() end
            elseif action == "always_on_top" then
                if w then w:toggle_always_on_top() end
            elseif action == "sticky" then
                if w then w:make_sticky() end
            elseif action == "skip_taskbar" then
                if w then w:set_skip_taskbar(not w.skip_taskbar) end
            elseif action == "skip_pager" then
                if w then w:set_skip_pager(not w.skip_pager) end
            elseif action == "minimize" then
                if w then w:minimize() end
            elseif action == "move_to_workspace" then
                local ws_num = tonumber(params[1])
                if w and ws_num then w:move_to_workspace(ws_num) end
            end
        elseif category == "workspace" then
            if action == "next" then
                self.workspaces:scroll_workspaces("right")
            elseif action == "prev" then
                self.workspaces:scroll_workspaces("left")
            elseif action == "toggle" then
                if ws then ws:toggle_visibility() end
            elseif tonumber(action) then
                self.workspaces:switch_to(tonumber(action))
            end
        elseif category == "layout" then
            if action == "next" then
                if ws then ws:next_layout()
                local ws2 = self.workspaces:get_current()
                if ws2 then ws2:arrange() end end
            elseif action == "prev" then
                if ws then ws:prev_layout()
                local ws2 = self.workspaces:get_current()
                if ws2 then ws2:arrange() end end
            elseif action == "incmaster" then
                self.master_count = self.master_count + 1
                if ws then
                    ws.master_count = self.master_count
                    ws:arrange()
                end
            elseif action == "decmaster" then
                self.master_count = math.max(1, self.master_count - 1)
                if ws then
                    ws.master_count = self.master_count
                    ws:arrange()
                end
            elseif action == "incmargin" then
                self.gap_size = self.gap_size + 2
                if ws then ws:arrange() end
            elseif action == "decmargin" then
                self.gap_size = math.max(0, self.gap_size - 2)
                if ws then ws:arrange() end
            elseif action == "swap_master" then
                if ws then ws:swap_master() end
            elseif action == "toggle_split" then
                self.layout_split_vertical = not self.layout_split_vertical
                if ws then ws:arrange() end
            elseif action == "resize" then
                if ws then ws:arrange() end
            elseif action == "shuffle" then
                if ws then ws:arrange() end
            elseif action == "info" then
                if ws then
                    local names = layout.list_layout_names()
                    local idx = ws.layout_index
                    print("Layout: " .. (names[idx] or "unknown") ..
                          " | Windows: " .. #ws.windows ..
                          " | Master: " .. ws.master_count)
                end
            elseif action == "fullscreen" then
                if ws then ws:set_layout("monocle") end
            elseif action == "floating" then
                if w then w:toggle_floating() end
            elseif action == "toggle" then
                if ws then ws:arrange() end
            end
        elseif category == "reload" then
            self:reload_config()
        elseif category == "restart" then
            self:restart()
        elseif category == "exit" then
            self:exit()
        elseif category == "bar" then
            if action == "toggle" then
            end
            if action == "reload" then
            end
        end

        return true
    end
end

return commands