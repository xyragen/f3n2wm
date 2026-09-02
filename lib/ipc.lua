local ipc = {}

ipc.wm = nil
ipc.socket_path = nil
ipc.socket = nil
ipc.handlers = {}
ipc.running = false
ipc.buffer = ""

function ipc.set_wm(wm)
    ipc.wm = wm
end

function ipc.register_command(name, handler)
    ipc.handlers[name] = handler
end

function ipc.init(config, base_path)
    local socket_name = config.ipc.socket_name or "f3n2wm-ipc"
    local run_dir = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
    ipc.socket_path = run_dir .. "/" .. socket_name

    ipc:register_default_commands()

    if config.ipc.enabled == false then
        return
    end

    local socket = nil
    local ok, err = pcall(function()
        socket = io.popen("rm -f '" .. ipc.socket_path .. "' 2>/dev/null; echo done")
        if socket then socket:close() end
    end)
    if not ok then
        ipc.socket_path = "/tmp/" .. socket_name
    end

    ipc.running = true
    return true
end

function ipc.register_default_commands()
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
                    wid,
                    w.name or "unknown",
                    w.class or "unknown",
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
        local commands = {}
        for name in pairs(ipc.handlers) do
            commands[#commands+1] = name
        end
        table.sort(commands)
        local result = {}
        for _, name in ipairs(commands) do
            result[#result+1] = name
        end
        return "Commands: " .. table.concat(result, ", ")
    end)
end

function ipc.execute_command(line)
    if not line or #line == 0 then return "" end
    local parts = {}
    for word in line:gmatch("[^%s]+") do
        parts[#parts+1] = word
    end
    if #parts == 0 then return "error: empty command" end
    local cmd_name = parts[1]
    local args = {}
    for i = 2, #parts do
        args[i-1] = parts[i]
    end
    local handler = ipc.handlers[cmd_name]
    if not handler then
        return "error: unknown command: " .. cmd_name
    end
    local ok, result = pcall(handler, args)
    if not ok then
        return "error: " .. tostring(result)
    end
    return result
end

function ipc.handle_connection(data)
    local lines = {}
    for line in data:gmatch("([^\n]*)") do
        if #line > 0 then
            lines[#lines+1] = line
        end
    end
    local results = {}
    for _, line in ipairs(lines) do
        local result = ipc.execute_command(line)
        results[#results+1] = result
    end
    return table.concat(results, "\n") .. "\n"
end

function ipc.poll()
    if not ipc.running then return end
    local cmd = "ls -la '" .. ipc.socket_path .. "' 2>/dev/null | grep -c socket"
    local handle = io.popen(cmd)
    if handle then
        local result = handle:read("*number")
        handle:close()
        if result and result > 0 then
            local read_cmd = "echo '' | socat - UNIX-CONNECT:" .. ipc.socket_path .. " 2>/dev/null"
            local read_handle = io.popen(read_cmd)
            if read_handle then
                local data = read_handle:read("*all")
                read_handle:close()
                if data and #data > 0 then
                    local response = ipc.handle_connection(data)
                    local write_cmd = "echo -n '" .. response:gsub("'", "'\\''") .. "' | socat - UNIX-CONNECT:" .. ipc.socket_path .. " 2>/dev/null"
                    os.execute(write_cmd)
                end
            end
        end
    end
end

function ipc.send_command(command)
    local socket_path = ipc.socket_path or "/tmp/f3n2wm-ipc"
    local cmd = "echo '" .. command .. "' | socat - UNIX-CONNECT:" .. socket_path .. " 2>/dev/null"
    local handle = io.popen(cmd)
    if handle then
        local response = handle:read("*all")
        handle:close()
        return response
    end
    return nil
end

function ipc.shutdown()
    ipc.running = false
    ipc.handlers = {}
    ipc.buffer = ""
    local ok, err = pcall(function()
        os.remove(ipc.socket_path)
    end)
end

function ipc.init_unix_socket()
    if ipc.socket_path then
        os.execute("rm -f '" .. ipc.socket_path .. "' 2>/dev/null")
    end
    return true
end

return ipc
