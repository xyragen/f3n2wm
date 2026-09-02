local input = {}
input.wm = nil
input.bindings = {}
input.mouse_bindings = {}
input.modmap = {}
input.mod_mask_map = {}
input.drag_state = nil

function input.set_wm(wm)
    input.wm = wm
end

local modifier_names = {
    Shift = 0x0001,
    Lock = 0x0002,
    Control = 0x0004,
    Mod1 = 0x0008,
    Mod2 = 0x0010,
    Mod3 = 0x0020,
    Mod4 = 0x0040,
    Mod5 = 0x0080,
}

function input.parse_modifiers(str, real_mods)
    if not str then return 0 end
    local mods = 0
    for mod in str:gmatch("[^-]+") do
        local mask = modifier_names[mod]
        if mask then
            mods = mods | mask
        end
    end
    return mods
end

function input.build_modifier_map(actual_mods)
    local mod_map = {}
    local real_mods = actual_mods or input.modmap
    for name, mask in pairs(modifier_names) do
        mod_map[name] = mask
        mod_map[string.lower(name)] = mask
    end
    mod_map["M"] = real_mods.Mod4 or 0x0040
    mod_map["S"] = real_mods.Shift or 0x0001
    mod_map["C"] = real_mods.Control or 0x0004
    mod_map["A"] = real_mods.Mod1 or 0x0008
    return mod_map
end

function input.parse_keybinding(key_str)
    local parts = {}
    for mod in key_str:gmatch("[^-]+") do
        parts[#parts+1] = mod
    end
    if #parts == 0 then return nil, 0 end
    local key = parts[#parts]
    local mod_str = ""
    for i = 1, #parts - 1 do
        if i > 1 then mod_str = mod_str .. "-" end
        mod_str = mod_str .. parts[i]
    end
    return key, mod_str
end

function input.resolve_keycode(key_name)
    local X11 = input.wm.x11
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

function input.setup_bindings(config)
    local X11 = input.wm.x11
    local root = X11.root

    input.modmap = X11.get_modifier_map()
    input.mod_mask_map = input.build_modifier_map({
        Shift = input.modmap[1],
        Lock = input.modmap[2],
        Control = input.modmap[3],
        Mod1 = input.modmap[4],
        Mod2 = input.modmap[5],
        Mod3 = input.modmap[6],
        Mod4 = input.modmap[7],
        Mod5 = input.modmap[8],
    })

    for key_str, command in pairs(config.bindings or {}) do
        if type(key_str) ~= "number" then
            local key_name, mod_str = input.parse_keybinding(key_str)
            if key_name and not key_str:find("Button") then
                local keycode = input.resolve_keycode(key_name)
                if keycode then
                    local mod_mask = 0
                    if mod_str and #mod_str > 0 then
                        mod_mask = input.parse_modifiers(mod_str, input.mod_mask_map)
                    end
                    X11.grab_key(root, keycode, mod_mask)
                    input.bindings[keycode .. ":" .. mod_mask] = command
                end
            end
        end
    end

    for key_str, command in pairs(config.mouse or {}) do
        if type(key_str) ~= "number" then
            local key_name, mod_str = input.parse_keybinding(key_str)
            if key_name and key_str:find("Button") then
                local button_num = tonumber(key_name:match("Button(%d+)"))
                if button_num then
                    local mod_mask = 0
                    if mod_str and #mod_str > 0 then
                        mod_mask = input.parse_modifiers(mod_str, input.mod_mask_map)
                    end
                    X11.grab_button(root, tonumber(button_num), mod_mask)
                    input.mouse_bindings[button_num .. ":" .. mod_mask] = command
                end
            end
        end
    end
end

function input.parse_modifiers_from_event(state)
    local mods = {}
    for name, mask in pairs(modifier_names) do
        if (state & mask) ~= 0 then
            mods[#mods+1] = name
        end
    end
    return mods
end

function input.handle_key_press(event)
    local keycode = tonumber(event.key) or event.keycode
    local state = tonumber(event.state or 0)
    local mod_mask = state
    local key, mod_str = input.parse_modifiers_from_event(state)
    local binding_key = keycode .. ":" .. mod_mask
    local command = input.bindings[binding_key]
    if not command then
        for k, v in pairs(input.bindings) do
            local kc, ms = k:match("(%d+):(%d+)")
            if tonumber(kc) == keycode then
                local mask_match = true
                local stored_mod = tonumber(ms)
                if mod_mask & stored_mod == stored_mod and stored_mod & mod_mask == stored_mod then
                    command = v
                    break
                end
            end
        end
    end
    if command then
        local wm = input.wm
        local result = wm.commands.execute(command, event)
        local cancel = wm.hooks.fire("key_press", event, command)
        if cancel == false then return end
    end
end

function input.handle_key_release(event)
    input.wm.hooks.fire("key_release", event)
end

function input.handle_button_press(event)
    local button = tonumber(event.button)
    local state = tonumber(event.state or 0)
    local binding_key = button .. ":" .. state
    local command = input.mouse_bindings[binding_key]

    if command then
        local result = input.wm.commands.execute(command, event)
    else
        local X11 = input.wm.x11
        if input.drag_state then
            local w = X11.get_input_focus()
            local win = input.wm.windows.get(w)
            if win then
                local ptr = X11.get_pointer_position()
                if input.drag_state.type == "move" then
                    local dx = ptr.x - (input.drag_state.start_x or 0)
                    local dy = ptr.y - (input.drag_state.start_y or 0)
                    X11.move_window(win.id,
                        (input.drag_state.win_x or 0) + dx,
                        (input.drag_state.win_y or 0) + dy)
                elseif input.drag_state.type == "resize" then
                    local dx = ptr.x - (input.drag_state.start_x or 0)
                    local dy = ptr.y - (input.drag_state.start_y or 0)
                    local new_w = math.max(100, (input.drag_state.win_w or 0) + dx)
                    local new_h = math.max(100, (input.drag_state.win_h or 0) + dy)
                    X11.resize_window(win.id, new_w, new_h)
                end
                input.wm.hooks.fire("drag_update", win, ptr)
            end
        else
            if event.button == 1 then
                input.drag_state = {
                    type = "move",
                    start_x = X11.get_pointer_position().x,
                    start_y = X11.get_pointer_position().y,
                    win_x = 0,
                    win_y = 0,
                    win_w = 0,
                    win_h = 0,
                }
                local ptr = X11.get_pointer_position()
                input.drag_state.start_x = ptr.x
                input.drag_state.start_y = ptr.y
            elseif event.button == 2 then
                input.drag_state = {
                    type = "resize",
                    start_x = X11.get_pointer_position().x,
                    start_y = X11.get_pointer_position().y,
                }
            end
            if input.drag_state then
                local w = X11.get_input_focus()
                local win = input.wm.windows.get(w)
                if win then
                    local geom = X11.get_window_geometry(win.id)
                    if geom then
                        input.drag_state.win_x = geom.x
                        input.drag_state.win_y = geom.y
                        input.drag_state.win_w = geom.width
                        input.drag_state.win_h = geom.height
                    end
                end
            end
        end
    end
    input.wm.hooks.fire("button_press", event, command)
end

function input.handle_button_release(event)
    if input.drag_state then
        input.drag_state = nil
    end
    input.wm.hooks.fire("button_release", event)
end

function input.handle_motion(event)
    if input.drag_state then
        local X11 = input.wm.x11
        local w = X11.get_input_focus()
        local win = input.wm.windows.get(w)
        if win then
            local ptr = X11.get_pointer_position()
            if input.drag_state.type == "move" then
                local dx = ptr.x - input.drag_state.start_x
                local dy = ptr.y - input.drag_state.start_y
                X11.move_window(win.id,
                    input.drag_state.win_x + dx,
                    input.drag_state.win_y + dy)
            elseif input.drag_state.type == "resize" then
                local dx = ptr.x - input.drag_state.start_x
                local dy = ptr.y - input.drag_state.start_y
                local new_w = math.max(100, input.drag_state.win_w + dx)
                local new_h = math.max(100, input.drag_state.win_h + dy)
                X11.resize_window(win.id, new_w, new_h)
            end
            input.wm.hooks.fire("drag_update", win, ptr)
        end
    end
end

function input.handle_enter_notify(event)
    input.wm.hooks.fire("mouse_enter", event)
end

function input.handle_leave_notify(event)
    input.wm.hooks.fire("mouse_leave", event)
end

return input