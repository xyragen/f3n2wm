local bit = require("bit")

local handlers = {}

function handlers.handle_key_press(input_mod, event)
    local keycode = tonumber(event.keycode)
    local state = tonumber(event.state or 0)
    if not keycode then return end
    local binding_key = keycode .. ":" .. state
    local command = input_mod.bindings[binding_key]

    if not command then
        for k, v in pairs(input_mod.bindings) do
            local kc, ms = k:match("(%d+):(%d+)")
            if tonumber(kc) == keycode then
                local stored_mod = tonumber(ms)
                if bit.band(state, stored_mod) == stored_mod then
                    command = v
                    break
                end
            end
        end
    end

    if command then
        local wm = input_mod.wm
        wm:execute_command(command, event)
        local cancel = wm.hooks.fire("key_press", event, command)
        if cancel == false then return end
        wm.hooks.fire("key_press_post", event, command)
    end
end

function handlers.handle_key_release(input_mod, event)
    input_mod.wm.hooks.fire("key_release", event)
end

function handlers.handle_button_press(input_mod, event)
    local button = tonumber(event.button)
    local state = tonumber(event.state or 0)
    if not button then return end
    local binding_key = button .. ":" .. state
    local command = input_mod.mouse_bindings[binding_key]
    if command then
        input_mod.wm:execute_command(input_mod.wm, command, event)
    end
    input_mod.wm.hooks.fire("button_press", event, command)
end

function handlers.handle_button_release(input_mod, event)
    if input_mod.drag_state then input_mod.drag_state = nil end
    input_mod.wm.hooks.fire("button_release", event)
end

function handlers.handle_motion(input_mod, event)
    if input_mod.drag_state then
        local X11 = input_mod.wm.x11
        local win = input_mod.wm.windows.get_focused()
        if win then
            local ptr = X11.get_pointer_position()
            if input_mod.drag_state.type == "move" then
                local dx = ptr.x - input_mod.drag_state.start_x
                local dy = ptr.y - input_mod.drag_state.start_y
                X11.move_window(win.id, input_mod.drag_state.win_x + dx, input_mod.drag_state.win_y + dy)
            elseif input_mod.drag_state.type == "resize" then
                local dx = ptr.x - input_mod.drag_state.start_x
                local dy = ptr.y - input_mod.drag_state.start_y
                local new_w = math.max(100, input_mod.drag_state.win_w + dx)
                local new_h = math.max(100, input_mod.drag_state.win_h + dy)
                X11.resize_window(win.id, new_w, new_h)
            end
            input_mod.wm.hooks.fire("drag_update", win, ptr)
        end
    end
end

function handlers.handle_enter_notify(input_mod, event)
    input_mod.wm.hooks.fire("mouse_enter", event)
end

function handlers.handle_leave_notify(input_mod, event)
    input_mod.wm.hooks.fire("mouse_leave", event)
end

return handlers