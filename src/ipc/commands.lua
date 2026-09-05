local commands = {}

function commands.register_all(ipc)
    ipc.register_command("reload", function(args)
        ipc.wm:reload_config()
        return "ok: reloaded"
    end)

    ipc.register_command("restart", function(args)
        ipc.wm:restart()
        return "ok: restarting"
    end)

    ipc.register_command("exit", function(args)
        ipc.wm:exit()
        return "ok: exiting"
    end)

    ipc.register_command("list_workspaces", function(args)
        local result = {}
        for i, ws in ipairs(ipc.wm.workspaces:get_all()) do
            result[i] = string.format('[%d] %s%s (%d windows, %s)',
                i, ws.name,
                (i == ipc.wm.workspaces.current_ws) and ' *' or '',
                #ws.windows, ws.layout)
        end
        return table.concat(result, '\n')
    end)

    ipc.register_command("switch_workspace", function(args)
        local ws_num = tonumber(args[1])
        if ws_num then
            ipc.wm.workspaces:switch_to(ws_num)
            return "ok: switched to workspace " .. ws_num
        end
        return "error: invalid workspace number"
    end)

    ipc.register_command("move_window_to_workspace", function(args)
        local ws_num = tonumber(args[1])
        local focused = ipc.wm.windows.get_focused()
        if focused and ws_num then
            focused:move_to_workspace(ws_num)
            return "ok: moved window to workspace " .. ws_num
        end
        return "error: no focused window or invalid workspace"
    end)

    ipc.register_command("list_windows", function(args)
        local ws = ipc.wm.workspaces:get_current()
        if not ws then return "No windows" end
        local result = {}
        for i, wid in ipairs(ws.windows) do
            local w = ipc.wm.windows.get(wid)
            if w then
                result[i] = string.format('%d: %s [%s]%s',
                    wid, w.name or "unknown", w.class or "unknown",
                    (w.focused == true) and " (focused)" or "")
            end
        end
        return table.concat(result, '\n')
    end)

    ipc.register_command("next_layout", function(args)
        local ws = ipc.wm.workspaces:get_current()
        if ws then
            ws:next_layout()
            return "ok: layout is now " .. ws.layout
        end
        return "error: no current workspace"
    end)

    ipc.register_command("set_layout", function(args)
        local layout_name = args[1]
        if layout_name then
            local ws = ipc.wm.workspaces:get_current()
            if ws then
                ws:set_layout(layout_name)
                return "ok: layout set to " .. layout_name
            end
        end
        return "error: invalid layout"
    end)

    ipc.register_command("focus_window", function(args)
        local wid = tonumber(args[1])
        if wid then
            local ws = ipc.wm.workspaces:get_current()
            if ws then
                ws:focus_window(wid)
                return "ok: focused window " .. wid
            end
        end
        return "error: invalid window id"
    end)

    ipc.register_command("close_window", function(args)
        local focused = ipc.wm.windows.get_focused()
        if focused then
            focused:close()
            return "ok: closed window"
        end
        return "error: no focused window"
    end)

    ipc.register_command("kill_window", function(args)
        local focused = ipc.wm.windows.get_focused()
        if focused then
            focused:kill()
            return "ok: killed window"
        end
        return "error: no focused window"
    end)

    ipc.register_command("spawn", function(args)
        local cmd = table.concat(args, " ")
        if cmd and #cmd > 0 then
            os.execute(cmd .. " &")
            return "ok: spawned: " .. cmd
        end
        return "error: no command"
    end)

    ipc.register_command("get_active_window", function(args)
        local ws = ipc.wm.workspaces:get_current()
        if ws and ws.focused then
            return "ok: " .. ws.focused
        end
        return "none"
    end)

    ipc.register_command("get_current_workspace", function(args)
        return "ok: " .. ipc.wm.workspaces.current_ws
    end)

    ipc.register_command("set_border_width", function(args)
        local width = tonumber(args[1])
        if width then
            ipc.wm.config.border_width = width
            return "ok: border width set to " .. width
        end
        return "error: invalid width"
    end)

    ipc.register_command("set_gap", function(args)
        local gap = tonumber(args[1])
        if gap then
            ipc.wm.config.gap_size = gap
            return "ok: gap set to " .. gap
        end
        return "error: invalid gap"
    end)

    ipc.register_command("set_master_ratio", function(args)
        local ratio = tonumber(args[1])
        if ratio and ratio > 0 and ratio < 1 then
            local ws = ipc.wm.workspaces:get_current()
            if ws then
                ws.master_ratio = ratio
                ws:arrange()
                return "ok: master ratio set to " .. ratio
            end
        end
        return "error: invalid ratio"
    end)

    ipc.register_command("toggle_floating", function(args)
        local focused = ipc.wm.windows.get_focused()
        if focused then
            focused:toggle_floating()
            return "ok: toggled floating"
        end
        return "error: no focused window"
    end)

    ipc.register_command("toggle_fullscreen", function(args)
        local focused = ipc.wm.windows.get_focused()
        if focused then
            focused.fullscreen = not focused.fullscreen
            local ws = ipc.wm.workspaces:get_current()
            if ws then ws:arrange() end
            return "ok: toggled fullscreen"
        end
        return "error: no focused window"
    end)

    ipc.register_command("help", function(args)
        local cmds = {}
        for name in pairs(ipc.handlers) do cmds[#cmds+1] = name end
        table.sort(cmds)
        return "Commands: " .. table.concat(cmds, ", ")
    end)
end

return commands