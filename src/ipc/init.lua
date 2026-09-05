local bit = require("bit")
local ffi = require("ffi")
local debug = require("debug")
local commands = require("ipc.commands")

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

function ipc.set_wm(wm) ipc.wm = wm end

function ipc.register_command(name, handler)
    ipc.handlers[name] = handler
end

function ipc.register_default_commands()
    commands.register_all(ipc)
end

function ipc.execute_command(line)
    if not line or #line == 0 then return "" end
    local parts = {}
    for word in line:gmatch("[^%s]+") do parts[#parts+1] = word end
    if #parts == 0 then return "error: empty command" end
    local cmd_name = parts[1]
    local args = {}
    for i = 2, #parts do args[i-1] = parts[i] end
    local handler = ipc.handlers[cmd_name]
    if not handler then return "error: unknown command: " .. cmd_name end
    local ok, result = pcall(handler, args)
    if not ok then return "error: " .. tostring(result) end
    return tostring(result or "")
end

function ipc.handle_connection(data)
    local lines = {}
    for line in data:gmatch("([^\n]*)") do
        if #line > 0 then lines[#lines+1] = line end
    end
    local results = {}
    for _, line in ipairs(lines) do
        results[#results+1] = ipc.execute_command(line)
    end
    return table.concat(results, "\n") .. "\n"
end

function ipc.init(config, base_path)
    local cfg = (config and config.ipc) or {}
    ipc.socket_path = cfg.socket_path or "/tmp/f3n2wm-ipc.sock"
    ipc.register_default_commands()

    if cfg.enabled == false then return false end

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
        if ffi.C.listen(fd, 8) < 0 then ffi.C.close(fd) error("listen() failed") end
        local flags = tonumber(ffi.C.fcntl(fd, F_GETFL, 0)) or 0
        ffi.C.fcntl(fd, F_SETFL, bit.bor(flags, O_NONBLOCK))
        ipc.server_fd = fd
    end)

    if not ok then
        ipc.server_fd = nil
        ipc.running = false
        debug.error("ipc", "init failed: " .. tostring(err))
        return false, tostring(err)
    end

    ipc.running = true
    debug.info("ipc", "listening on " .. ipc.socket_path)
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
            ffi.C.close(fd) error("connect() failed on " .. ipc.socket_path)
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
    if ipc.server_fd then pcall(function() ffi.C.close(ipc.server_fd) end) ipc.server_fd = nil end
    if ipc.socket_path then pcall(function() ffi.C.unlink(ipc.socket_path) end) end
    ipc.handlers = {}
end

return ipc