local parse = require("input.parse")
local handlers = require("input.handlers")

local input = {}
input.wm = nil
input.bindings = {}
input.mouse_bindings = {}
input.modmap = {}
input.mod_mask_map = {}
input.drag_state = nil

function input.set_wm(wm) input.wm = wm end

function input.build_modifier_map(actual_mods)
    return parse.build_modifier_map(actual_mods)
end

function input.parse_modifiers(str, mod_map)
    return parse.parse_modifiers(str, mod_map)
end

function input.parse_keybinding(key_str)
    return parse.parse_keybinding(key_str)
end

function input.resolve_keycode(key_name)
    return parse.resolve_keycode(key_name, input.wm.x11)
end

function input.setup_bindings(config)
    local X11 = input.wm.x11
    local root = X11.root

    input.modmap = X11.get_modifier_map()
    input.mod_mask_map = parse.build_modifier_map({
        Shift = input.modmap[1], Lock = input.modmap[2],
        Control = input.modmap[3], Mod1 = input.modmap[4],
        Mod2 = input.modmap[5], Mod3 = input.modmap[6],
        Mod4 = input.modmap[7], Mod5 = input.modmap[8],
    })

    for key_str, command in pairs(config.keybindings or {}) do
        if type(key_str) == "string" then
            local key_name, mod_str = parse.parse_keybinding(key_str)
            if key_name and not key_str:find("Button") then
                local keycode = parse.resolve_keycode(key_name, X11)
                if keycode then
                    local mod_mask = parse.parse_modifiers(mod_str, input.mod_mask_map)
                    X11.grab_key(root, keycode, mod_mask)
                    input.bindings[keycode .. ":" .. mod_mask] = command
                end
            end
        end
    end

    for key_str, command in pairs(config.mousebinds or {}) do
        if type(key_str) == "string" then
            local key_name, mod_str = parse.parse_keybinding(key_str)
            if key_name and key_str:find("Button") then
                local button_num = tonumber(key_name:match("Button(%d+)"))
                if button_num then
                    local mod_mask = parse.parse_modifiers(mod_str, input.mod_mask_map)
                    X11.grab_button(root, button_num, mod_mask)
                    input.mouse_bindings[button_num .. ":" .. mod_mask] = command
                end
            end
        end
    end
end

function input.parse_modifiers_from_event(state)
    return parse.parse_modifiers_from_event(state)
end

function input.handle_key_press(event) handlers.handle_key_press(input, event) end
function input.handle_key_release(event) handlers.handle_key_release(input, event) end
function input.handle_button_press(event) handlers.handle_button_press(input, event) end
function input.handle_button_release(event) handlers.handle_button_release(input, event) end
function input.handle_motion(event) handlers.handle_motion(input, event) end
function input.handle_enter_notify(event) handlers.handle_enter_notify(input, event) end
function input.handle_leave_notify(event) handlers.handle_leave_notify(input, event) end

return input