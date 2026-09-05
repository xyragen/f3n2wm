local debug = {}

debug.levels = { debug = 1, info = 2, warn = 3, error = 4, silent = 5 }
debug.level = debug.levels.info
debug.log_to_stdout = true
debug.log_file = nil
debug._file_handle = nil

function debug.configure(cfg)
    cfg = cfg or {}
    debug.level = debug.levels[cfg.log_level or "info"] or debug.levels.info
    debug.log_to_stdout = cfg.log_to_stdout ~= false
    debug.log_file = cfg.log_file
    if debug.log_file then
        debug.log_file = debug.log_file:gsub("^~", os.getenv("HOME") or "")
        local ok, f = pcall(io.open, debug.log_file, "a")
        if ok and f then
            debug._file_handle = f
        else
            debug._file_handle = nil
        end
    end
end

function debug._write(level, tag, msg)
    if level < debug.level then return end
    local name = "debug"
    for k, v in pairs(debug.levels) do
        if v == level then name = k break end
    end
    local line = string.format("[%s][%s] %s", name:upper(), tag or "wm", msg)
    if debug.log_to_stdout then
        print(line)
    end
    if debug._file_handle then
        debug._file_handle:write(line .. "\n")
        debug._file_handle:flush()
    end
end

function debug.log(level, tag, msg)
    debug._write(level, tag, msg)
end

function debug.info(tag, msg) debug._write(debug.levels.info, tag, msg) end
function debug.warn(tag, msg) debug._write(debug.levels.warn, tag, msg) end
function debug.error(tag, msg) debug._write(debug.levels.error, tag, msg) end
function debug.debug(tag, msg) debug._write(debug.levels.debug, tag, msg) end

function debug.close()
    if debug._file_handle then
        debug._file_handle:close()
        debug._file_handle = nil
    end
end

return debug