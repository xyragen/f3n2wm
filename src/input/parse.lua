local bit = require("bit")

local parse = {}

parse.modifier_names = {
    Shift = 0x0001, Lock = 0x0002, Control = 0x0004,
    Mod1 = 0x0008, Mod2 = 0x0010, Mod3 = 0x0020,
    Mod4 = 0x0040, Mod5 = 0x0080,
}

function parse.build_modifier_map(actual_mods)
    local mod_map = {}
    local real_mods = actual_mods or {}
    for name, mask in pairs(parse.modifier_names) do
        mod_map[name] = mask
        mod_map[string.lower(name)] = mask
    end
    mod_map["M"] = real_mods.Mod4 or 0x0040
    mod_map["S"] = real_mods.Shift or 0x0001
    mod_map["C"] = real_mods.Control or 0x0004
    mod_map["A"] = real_mods.Mod1 or 0x0008
    return mod_map
end

function parse.parse_modifiers(str, mod_map)
    if not str then return 0 end
    local mods = 0
    local map = mod_map or {}
    for mod in str:gmatch("[^_]+") do
        local mask = map[mod] or parse.modifier_names[mod]
        if mask then mods = bit.bor(mods, mask) end
    end
    return mods
end

function parse.parse_keybinding(key_str)
    local parts = {}
    for part in key_str:gmatch("[^_]+") do parts[#parts+1] = part end
    if #parts == 0 then return nil, "" end
    local key = parts[#parts]
    local mods = {}
    for i = 1, #parts - 1 do mods[#mods+1] = parts[i] end
    return key, table.concat(mods, "_")
end

function parse.resolve_keycode(key_name, X11)
    local key_syms = {
        Return = 0xFF0D, space = 0x0020, Space = 0x0020,
        Tab = 0xFF09, Escape = 0xFF1B, BackSpace = 0xFF08,
        Delete = 0xFFFF, Up = 0xFF52, Down = 0xFF54,
        Left = 0xFF51, Right = 0xFF53,
        a = 0x0061, b = 0x0062, c = 0x0063, d = 0x0064,
        e = 0x0065, f = 0x0066, g = 0x0067, h = 0x0068,
        i = 0x0069, j = 0x006A, k = 0x006B, l = 0x006C,
        m = 0x006D, n = 0x006E, o = 0x006F, p = 0x0070,
        q = 0x0071, r = 0x0072, s = 0x0073, t = 0x0074,
        u = 0x0075, v = 0x0076, w = 0x0077, x = 0x0078,
        y = 0x0079, z = 0x007A,
        A = 0x0041, B = 0x0042, C = 0x0043, D = 0x0044,
        E = 0x0045, F = 0x0046, G = 0x0047, H = 0x0048,
        I = 0x0049, J = 0x004A, K = 0x004B, L = 0x004C,
        M = 0x004D, N = 0x004E, O = 0x004F, P = 0x0050,
        Q = 0x0051, R = 0x0052, S = 0x0053, T = 0x0054,
        U = 0x0055, V = 0x0056, W = 0x0057, X = 0x0058,
        Y = 0x0059, Z = 0x005A,
        ["1"] = 0x0031, ["2"] = 0x0032, ["3"] = 0x0033,
        ["4"] = 0x0034, ["5"] = 0x0035, ["6"] = 0x0036,
        ["7"] = 0x0037, ["8"] = 0x0038, ["9"] = 0x0039,
        ["0"] = 0x0030,
        comma = 0x002C, period = 0x002E, slash = 0x002F,
        semicolon = 0x003B, apostrophe = 0x0027,
        bracketleft = 0x005B, bracketright = 0x005D,
        minus = 0x002D, equal = 0x003D, backslash = 0x005C,
    }
    local sym = key_syms[key_name]
    if not sym then return nil end
    return X11.keysym_to_keycode(sym)
end

function parse.parse_modifiers_from_event(state)
    local mods = {}
    for name, mask in pairs(parse.modifier_names) do
        if bit.band(state, mask) ~= 0 then mods[#mods+1] = name end
    end
    return mods
end

return parse