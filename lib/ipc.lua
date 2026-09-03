local bit = require("bit")
local ffi = require("ffi")

ffi.cdef[[
struct sockaddr_un {
    unsigned short sun_family;
    char sun_path[108];
};

int socket(int domain, int type, int protocol);
int bind(int fd, const void *addr, unsigned int addrlen);
int listen(int fd, int backlog);
int accept(int fd, void *addr, unsigned int *addrlen);
int connect(int fd, const void *addr, unsigned int addrlen);
int recv(int fd, void *buf, unsigned int len, int flags);
int send(int fd, const void *buf, unsigned int len, int flags);
int close(int fd);
int unlink(const char *pathname);
int fcntl(int fd, int cmd, ...);
]]

local ipc = {}

ipc.wm = nil
ipc.socket_path = nil
ipc.server_fd = nil
ipc.handlers = {}
ipc.running = false

local AF_UNIX = 1
local SOCK_STREAM = 1
local F_GETFL = 3
local F_SETFL = 4
local O_NONBLOCK = 0x800
local MSG_DONTWAIT = 0x40

function ipc.set_wm(wm)
    ipc.wm = wm
end

function ipc.register_command(name, handler)
    ipc.handlers[name] = handler
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
        return "Commands: " .. table.concat(commands, ", ")
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
    return tostring(result or "")
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

function ipc.init(config, base_path)
    local cfg = (config and config.ipc) or {}
    ipc.socket_path = cfg.socket_path or "/tmp/f3n2wm-ipc.sock"

    ipc.register_default_commands()

    if cfg.enabled == false then
        return false
    end

    local ok, err = pcall(function()
        ffi.C.unlink(ipc.socket_path)
        local fd = ffi.C.socket(AF_UNIX, SOCK_STREAM, 0)
        if fd < 0 then error("socket() failed") end
        local addr = ffi.new("struct sockaddr_un")
        addr.sun_family = AF_UNIX
        ffi.copy(addr.sun_path, ipc.socket_path)
        if ffi.C.bind(fd, ffi.cast("const void*", addr), ffi.sizeof(addr)) < 0 then
            ffi.C.close(fd)
            error("bind() failed on " .. ipc.socket_path)
        end
        if ffi.C.listen(fd, 8) < 0 then
            ffi.C.close(fd)
            error("listen() failed")
        end
        local flags = tonumber(ffi.C.fcntl(fd, F_GETFL, 0)) or 0
        ffi.C.fcntl(fd, F_SETFL, bit.bor(flags, O_NONBLOCK))
        ipc.server_fd = fd
    end)

    if not ok then
        ipc.server_fd = nil
        ipc.running = false
        return false, tostring(err)
    end

    ipc.running = true
    return true
end

function ipc.poll()
    if not ipc.running or not ipc.server_fd then return end

    local client_fd = ffi.C.accept(ipc.server_fd, nil, nil)
    if client_fd < 0 then return end

    local buf = ffi.new("char[4096]")
    local data = {}
    while true do
        local n = ffi.C.recv(client_fd, buf, 4096, MSG_DONTWAIT)
        if n <= 0 then break end
        data[#data+1] = ffi.string(buf, n)
        if n < 4096 then break end
    end

    local request = table.concat(data)
    if #request > 0 then
        local response = ipc.handle_connection(request)
        ffi.C.send(client_fd, response, #response, 0)
    end

    ffi.C.close(client_fd)
end

function ipc.send_command(command)
    if not ipc.socket_path then return nil end

    local ok, result = pcall(function()
        local fd = ffi.C.socket(AF_UNIX, SOCK_STREAM, 0)
        if fd < 0 then error("socket() failed") end
        local addr = ffi.new("struct sockaddr_un")
        addr.sun_family = AF_UNIX
        ffi.copy(addr.sun_path, ipc.socket_path)
        if ffi.C.connect(fd, ffi.cast("const void*", addr), ffi.sizeof(addr)) < 0 then
            ffi.C.close(fd)
            error("connect() failed on " .. ipc.socket_path)
        end
        ffi.C.send(fd, command .. "\n", #command + 1, 0)
        local buf = ffi.new("char[4096]")
        local chunks = {}
        while true do
            local n = ffi.C.recv(fd, buf, 4096, MSG_DONTWAIT)
            if n <= 0 then break end
            chunks[#chunks+1] = ffi.string(buf, n)
        end
        ffi.C.close(fd)
        return table.concat(chunks)
    end)

    if ok then return result end
    return nil, result
end

function ipc.shutdown()
    ipc.running = false
    if ipc.server_fd then
        pcall(function()
            ffi.C.close(ipc.server_fd)
        end)
        ipc.server_fd = nil
    end
    if ipc.socket_path then
        pcall(function()
            ffi.C.unlink(ipc.socket_path)
        end)
    end
    ipc.handlers = {}
end

return ipc