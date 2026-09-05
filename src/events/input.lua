local bit = require("bit")
local X11 = require("x11")
local hook = require("hook")
local window = require("window")

local input_events = {}

function input_events.install(wm)
    function wm:handle_key_press(event)
        local keycode = tonumber(event.xkey.keycode)
        local state = tonumber(event.xkey.state)
        if not keycode then return end

        local binding_key = keycode .. ":" .. state
        local command = self.keybindings[binding_key]

        if not command then
            for k, v in pairs(self.keybindings) do
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
            local cancel = hook.fire("key_press", event, command)
            if cancel == false then return end
            self:execute_command(command, event)
            hook.fire("key_press_post", event, command)
        else
            hook.fire("key_press", event)
        end
    end

    function wm:handle_key_release(event)
        hook.fire("key_release", event)
    end

    function wm:handle_button_press(event)
        local button = tonumber(event.xbutton.button)
        local state = tonumber(event.xbutton.state or 0)

        local binding_key = "btn:" .. button .. ":" .. state
        local action = self.keybindings[binding_key]

        if not action then
            for k, v in pairs(self.keybindings) do
                if k:match("^btn:") then
                    local btn, ms = k:match("btn:(%d+):(%d+)")
                    if tonumber(btn) == button then
                        local stored_mod = tonumber(ms)
                        if bit.band(state, stored_mod) == stored_mod then
                            action = v
                            break
                        end
                    end
                end
            end
        end

        if action == "move" then
            self.input.drag_state = {
                type = "move",
                start_x = X11.get_pointer_position().x,
                start_y = X11.get_pointer_position().y,
            }
            local w = window.get_focused()
            if w then
                local geom = X11.get_window_geometry(w.id)
                if geom then
                    self.input.drag_state.win_x = geom.x
                    self.input.drag_state.win_y = geom.y
                    self.input.drag_state.win_w = geom.width
                    self.input.drag_state.win_h = geom.height
                end
            end
            X11.grab_pointer(w and w.id or X11.root)
        elseif action == "resize" then
            self.input.drag_state = {
                type = "resize",
                start_x = X11.get_pointer_position().x,
                start_y = X11.get_pointer_position().y,
            }
            local w = window.get_focused()
            if w then
                local geom = X11.get_window_geometry(w.id)
                if geom then
                    self.input.drag_state.win_w = geom.width
                    self.input.drag_state.win_h = geom.height
                end
                X11.grab_pointer(w.id)
            end
        elseif action == "move_to_workspace" then
            local w = window.get_focused()
            if w then
                w:move_to_workspace(self.workspaces.current_ws + 1)
            end
        end

        hook.fire("button_press", event, action)
    end

    function wm:handle_button_release(event)
        if self.input.drag_state then
            self.input.drag_state = nil
            X11.ungrab_pointer()
        end
        local ws = self.workspaces:get_current()
        if ws then ws:arrange() end
        hook.fire("button_release", event)
    end

    function wm:handle_motion_notify(event)
        local drag = self.input.drag_state
        if drag then
            local ptr = X11.get_pointer_position()
            local w = window.get_focused()
            if w then
                if drag.type == "move" then
                    local dx = ptr.x - drag.start_x
                    local dy = ptr.y - drag.start_y
                    X11.move_window(w.id, drag.win_x + dx, drag.win_y + dy)
                elseif drag.type == "resize" then
                    local dx = ptr.x - drag.start_x
                    local dy = ptr.y - drag.start_y
                    local new_w = math.max(100, drag.win_w + dx)
                    local new_h = math.max(100, drag.win_h + dy)
                    X11.resize_window(w.id, new_w, new_h)
                    w:update_geometry(drag.win_x or 0, drag.win_y or 0, new_w, new_h)
                end
            end
            hook.fire("drag_update", w, ptr)
        end
    end

    function wm:handle_enter_notify(event)
        hook.fire("mouse_enter", event)
        if self.config.focus_follows_mouse then
            local win_id = tonumber(event.xany.window)
            if win_id and win_id ~= X11.root then
                local w = window.get(win_id)
                if w and w.visible and not w.is_destroying then
                    self:focus_window(win_id)
                end
            end
        end
    end
end

return input_events