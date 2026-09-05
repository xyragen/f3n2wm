local toml = require("toml")
local debug = require("debug")

local loader = {}

local function deep_copy(t)
    if type(t) ~= "table" then return t end
    local result = {}
    for k, v in pairs(t) do
        if type(v) == "table" then result[k] = deep_copy(v) else result[k] = v end
    end
    return result
end

local function validate_layout(def, source)
    local errors = {}
    if not def.name then
        table.insert(errors, "missing 'name'")
    end
    if not def.algorithm then
        if not def.columns or #def.columns == 0 then
            table.insert(errors, "must define either 'columns' or 'algorithm'")
        else
            for i, col in ipairs(def.columns) do
                if not col.size and not col.count then
                    table.insert(errors, "column " .. i .. " missing 'size'")
                end
                if col.count ~= "fill" and not tonumber(col.count) then
                    table.insert(errors, "column " .. i .. " has invalid 'count' (use a number or \"fill\")")
                end
            end
        end
        if def.direction and def.direction ~= "vertical" and def.direction ~= "horizontal" then
            table.insert(errors, "direction must be \"vertical\" or \"horizontal\"")
        end
    end
    if #errors > 0 then
        debug.warn("layout", "invalid layout '" .. (def.name or "?") .. "' in " .. source .. ": " .. table.concat(errors, "; "))
        return false
    end
    return true
end

function loader.load_file(path)
    local parsed, err = toml.load(path)
    if not parsed then
        debug.error("layout", "failed to load " .. path .. ": " .. tostring(err))
        return nil
    end
    local layout = parsed.layout
    if not layout then
        debug.warn("layout", "no [layout] section in " .. path)
        return nil
    end
    if not validate_layout(layout, path) then return nil end
    debug.info("layout", "loaded preset '" .. layout.name .. "' from " .. path)
    return layout
end

function loader.load_dir(dir)
    local layouts = {}
    local handle = io.popen('ls "' .. dir .. '"/*.toml 2>/dev/null')
    if not handle then
        debug.warn("layout", "could not read preset dir: " .. dir)
        return layouts
    end
    for file in handle:lines() do
        local layout = loader.load_file(file)
        if layout then
            table.insert(layouts, layout)
        end
    end
    handle:close()
    return layouts
end

function loader.load_user_layouts(dir)
    if not dir then return {} end
    local layouts = {}
    local handle = io.popen('ls "' .. dir .. '"/*.toml 2>/dev/null')
    if not handle then return layouts end
    for file in handle:lines() do
        local parsed, err = toml.load(file)
        if parsed and parsed.layout then
            local layout = parsed.layout
            if validate_layout(layout, file) then
                table.insert(layouts, layout)
                debug.info("layout", "loaded user layout '" .. layout.name .. "' from " .. file)
            end
        elseif not parsed then
            debug.warn("layout", "skipping " .. file .. ": " .. tostring(err))
        end
    end
    handle:close()
    return layouts
end

return loader