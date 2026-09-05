local bit = require("bit")
local toml = require("toml")
local debug = require("debug")

local config = {}

config.key_names = {
    ["Mod1"] = 8, ["Mod2"] = 16, ["Mod3"] = 32, ["Mod4"] = 64, ["Mod5"] = 128,
    ["Shift"] = 1, ["Lock"] = 2, ["Control"] = 4, ["Alt"] = 8,
    ["Ctrl"] = 4, ["Super"] = 64, ["Hyper"] = 32,
    ["M"] = 64, ["S"] = 1, ["C"] = 4, ["A"] = 8,
}

config.keysyms = {
    Return = 0xff0d, space = 0x0020, Escape = 0xff1b, Tab = 0xff09,
    BackSpace = 0xff08, Delete = 0xffff, Insert = 0xff63, Home = 0xff50,
    Page_Up = 0xff55, Page_Down = 0xff56, End = 0xff57,
    Left = 0xff51, Up = 0xff52, Right = 0xff53, Down = 0xff54,
    F1 = 0xffbe, F2 = 0xffbf, F3 = 0xffc0, F4 = 0xffc1,
    F5 = 0xffc2, F6 = 0xffc3, F7 = 0xffc4, F8 = 0xffc5,
    F9 = 0xffc6, F10 = 0xffc7, F11 = 0xffc8, F12 = 0xffc9,
    equal = 0x003d, minus = 0x002d, period = 0x002e, comma = 0x002c,
}

local function deep_copy(t)
    if type(t) ~= "table" then return t end
    local result = {}
    for k, v in pairs(t) do
        if type(v) == "table" then result[k] = deep_copy(v) else result[k] = v end
    end
    return result
end

local function merge_tables(default, override)
    if type(default) ~= "table" or type(override) ~= "table" then return override end
    local result = deep_copy(default)
    for k, v in pairs(override) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = merge_tables(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

local function parse_key_string(str)
    local key, action = str:match("^([^=]+)=(.+)$")
    if not key then
        debug.warn("config", "malformed keybinding: " .. tostring(str))
        return nil
    end
    return key, action
end

local function parse_rule_string(str)
    local match, rest = str:match("^([^:]+):(.+)$")
    if not match then
        debug.warn("config", "malformed rule: " .. tostring(str))
        return nil
    end
    local rule = { match = match }
    for part in rest:gmatch("[^:]+") do
        local k, v = part:match("^(%w+)=(.+)$")
        if k and v then
            if v == "true" then rule[k] = true
            elseif v == "false" then rule[k] = false
            else
                local num = tonumber(v)
                rule[k] = num or v
            end
        end
    end
    return rule
end

local function load_toml_file(path)
    local parsed, err = toml.load(path)
    if not parsed then
        debug.error("config", "failed to load " .. path .. ": " .. tostring(err))
        return nil
    end
    debug.debug("config", "loaded " .. path)
    return parsed
end

local function load_config_dir(dir)
    local result = {}
    local handle = io.popen('ls "' .. dir .. '"/*.toml 2>/dev/null')
    if not handle then
        debug.warn("config", "could not read config dir: " .. dir)
        return result
    end
    for file in handle:lines() do
        local parsed = load_toml_file(file)
        if parsed then
            for k, v in pairs(parsed) do
                if type(v) == "table" and type(result[k]) == "table" then
                    result[k] = merge_tables(result[k], v)
                else
                    result[k] = v
                end
            end
        end
    end
    handle:close()
    return result
end

function config.load(base_path, user_dir)
    local default_dir = base_path .. "/src/config"
    local raw = load_config_dir(default_dir)

    if user_dir then
        local user_raw = load_config_dir(user_dir)
        for k, v in pairs(user_raw) do
            if type(v) == "table" and type(raw[k]) == "table" then
                raw[k] = merge_tables(raw[k], v)
            else
                raw[k] = v
            end
        end
    end

    local result = deep_copy(raw)

    if type(result.keybindings) == "table" then
        local parsed = {}
        for _, str in ipairs(result.keybindings) do
            local key, action = parse_key_string(str)
            if key then parsed[key] = action end
        end
        result.keybindings = parsed
    end

    if type(result.mousebinds) == "table" then
        local parsed = {}
        for _, str in ipairs(result.mousebinds) do
            local key, action = parse_key_string(str)
            if key then parsed[key] = action end
        end
        result.mousebinds = parsed
    end

    if type(result.rules) == "table" then
        local parsed = {}
        for _, str in ipairs(result.rules) do
            local rule = parse_rule_string(str)
            if rule then table.insert(parsed, rule) end
        end
        result.rules = parsed
    end

    if not result.layouts then
        result.layouts = { "master-stack", "grid", "tall", "wide", "spiral", "monocle" }
    end

    debug.info("config", "configuration ready: " .. tostring(raw.workspaces and raw.workspaces.count or "?") .. " workspaces, " .. tostring(#(result.rules or {})) .. " rules")

    return result
end

function config.get_modifier_mask(modkey)
    local result = 0
    for part in (modkey or ""):gmatch("[^_]+") do
        if config.key_names[part] then
            result = bit.bor(result, config.key_names[part])
        end
    end
    return result
end

function config.parse_keybinding(keybinding)
    local parts = {}
    for part in keybinding:gmatch("[^_]+") do parts[#parts+1] = part end
    local key = parts[#parts]
    local modifiers = {}
    for i = 1, #parts - 1 do modifiers[#modifiers+1] = parts[i] end
    local mod_mask = 0
    for _, mod in ipairs(modifiers) do
        if config.key_names[mod] then mod_mask = bit.bor(mod_mask, config.key_names[mod]) end
    end
    local keysym = config.keysyms[key]
    if not keysym then keysym = string.byte(key:sub(1, 1)) end
    return { modifiers = mod_mask, keysym = keysym, modifier_names = modifiers, key_name = key, raw = keybinding }
end

function config.parse_mousebind(mousebind)
    local parts = {}
    for part in mousebind:gmatch("[^_]+") do parts[#parts+1] = part end
    local button_str = parts[#parts]
    local modifiers = {}
    for i = 1, #parts - 1 do modifiers[#modifiers+1] = parts[i] end
    local mod_mask = 0
    for _, mod in ipairs(modifiers) do
        if config.key_names[mod] then mod_mask = bit.bor(mod_mask, config.key_names[mod]) end
    end
    local button_num = tonumber(button_str:match("Button(%d+)"))
    return { modifiers = mod_mask, button = button_num, modifier_names = modifiers, button_name = button_str, raw = mousebind }
end

function config.parse_rule(rule)
    if type(rule) == "table" then return rule end
    if type(rule) == "string" then return parse_rule_string(rule) end
    return nil
end

function config.expand_path(path)
    return (path or ""):gsub("^~", os.getenv("HOME") or "")
end

return config