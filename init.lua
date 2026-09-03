#!/usr/bin/env luajit

local args = {...}
local base_path = args[1] or "."

local bit = require("bit")

package.path = base_path .. "/lib/?.lua;" .. base_path .. "/?.lua;" ..
               base_path .. "/layouts/?.lua;" .. package.path

local ffi = require("ffi")
local toml = require("toml")
local X11 = require("x11")
local config = require("config")
local hook = require("hook")
local window = require("window")
local workspace_mod = require("workspace")
local layout = require("layout")
local input = require("input")
local ipc = require("ipc")

local MOD = {
    Shift = 0x0001, Lock = 0x0002, Control = 0x0004,
    Mod1 = 0x0008, Mod2 = 0x0010, Mod3 = 0x0020,
    Mod4 = 0x0040, Mod5 = 0x0080,
    M = 0x0040, S = 0x0001, C = 0x0004, A = 0x0008,
    Super = 0x0040, Ctrl = 0x0004, Alt = 0x0008,
}

local wm = {}
wm.base_path = base_path
wm.config = config.deep_copy(config.defaults)
wm.config_path = base_path .. "/f3n2wm.toml"
wm.x11 = X11
wm.hooks = hook
wm.windows = window
wm.layouts = layout
wm.input = input
wm.ipc = ipc
wm.running = true
wm.screen_width = 0
wm.screen_height = 0
wm.master_count = 1
wm.master_ratio = 0.5
wm.gap_size = 8
wm.border_focus = "#589cc9"
wm.border_unfocus = "#333333"
wm.border_width = 2
wm.is_exiting = false
wm.config_reload_pending = false
wm.keybindings = {}

function wm:set_modmaps(actual_mods)
end

function wm:parse_keybinding(key_str)
    local parts = {}
    for part in key_str:gmatch("[^_]+") do
        parts[#parts+1] = part
    end
    if #parts == 0 then return nil, 0 end
    local mod_names = {}
    local key_parts = {}
    local i = 1
    while i <= #parts do
        if MOD[parts[i]] then
            mod_names[#mod_names+1] = parts[i]
            i = i + 1
        else
            for j = i, #parts do
                key_parts[#key_parts+1] = parts[j]
            end
            break
        end
    end
    if #key_parts == 0 then return nil, 0 end
    local key_name = table.concat(key_parts, "_")
    local mod_mask = 0
    for _, mod_name in ipairs(mod_names) do
        local mask = MOD[mod_name]
        if mask then
            mod_mask = bit.bor(mod_mask, mask)
        end
    end
    return key_name, mod_mask
end

function wm:resolve_keycode(key_name)
    local keysym
    if config.keysyms and config.keysyms[key_name] then
        keysym = config.keysyms[key_name]
    else
        local upper = key_name:upper()
        if config.keysyms and config.keysyms[upper] then
            keysym = config.keysyms[upper]
        else
            if #key_name == 1 then
                keysym = string.byte(key_name:upper())
            else
                return nil
            end
        end
    end
    return X11.keysym_to_keycode(keysym)
end

function wm:setup_keybindings()
    local root = X11.root
    self.keybindings = {}

    if self.config.keybindings then
        for key_str, command in pairs(self.config.keybindings) do
            local key_name, mod_mask = self:parse_keybinding(key_str)
            if key_name then
                local keycode = self:resolve_keycode(key_name)
                if keycode then
                    X11.grab_key(root, keycode, mod_mask)
                    self.keybindings[keycode .. ":" .. mod_mask] = command
                end
            end
        end
    end

    if self.config.mousebinds then
        for mouse_str, action in pairs(self.config.mousebinds) do
            local parts = {}
            for part in mouse_str:gmatch("[^_]+") do
                parts[#parts+1] = part
            end
            if #parts >= 2 then
                local button_str = parts[#parts]
                local button_num = tonumber(button_str:match("Button(%d+)"))
                if button_num then
                    local mod_mask = 0
                    for i = 1, #parts - 1 do
                        local mask = MOD[parts[i]]
                        if mask then
                            mod_mask = bit.bor(mod_mask, mask)
                        end
                    end
                    X11.grab_button(root, button_num, mod_mask)
                    self.keybindings["btn:" .. button_num .. ":" .. mod_mask] = action
                end
            end
        end
    end
end

wm.commands = {}

function wm.commands.execute(self, command, event)
    if not command or #command == 0 then return false end
    local parts = {}
    for part in command:gmatch("([^:]+)") do
        parts[#parts+1] = part
    end
    local category = parts[1]
    local action = parts[2] or ""
    local params = {}
    for i = 3, #parts do params[i-2] = parts[i] end

    local w = window.get_focused()
    local ws = self.workspaces and self.workspaces:get_current()

    if category == "spawn" then
        local cmd = table.concat(parts, ":", 2)
        if cmd and #cmd > 0 then
            os.execute(cmd .. " &")
        end

    elseif category == "focus" then
        if action == "left" then window.focus_direction("left")
        elseif action == "right" then window.focus_direction("right")
        elseif action == "up" then window.focus_direction("up")
        elseif action == "down" then window.focus_direction("down")
        elseif action == "prev" then window.focus_prev()
        elseif action == "next" then window.focus_next()
        elseif action == "urgent" then window.focus_urgent()
        end

    elseif category == "move" then
        window.move_focused(action)

    elseif category == "resize" then
        if ws then
            if action == "left" or action == "up" then
                ws.master_ratio = math.max(0.1, ws.master_ratio - 0.05)
            else
                ws.master_ratio = math.min(0.9, ws.master_ratio + 0.05)
            end
            ws:arrange()
        end

    elseif category == "window" then
        if action == "close" then
            if w then w:close() end
        elseif action == "kill" then
            if w then w:kill() end
        elseif action == "maximize" then
            if w then
                if params[1] == "horizontal" then w.maximized_h = not w.maximized_h
                elseif params[1] == "vertical" then w.maximized_v = not w.maximized_v
                else w.maximized = not w.maximized end
                if ws then ws:arrange() end
            end
        elseif action == "fullscreen" then
            if w then w.fullscreen = not w.fullscreen
            if ws then ws:arrange() end end
        elseif action == "toggle_floating" then
            if w then w:toggle_floating() end
        elseif action == "always_on_top" then
            if w then w:toggle_always_on_top() end
        elseif action == "sticky" then
            if w then w:make_sticky() end
        elseif action == "skip_taskbar" then
            if w then w:set_skip_taskbar(not w.skip_taskbar) end
        elseif action == "skip_pager" then
            if w then w:set_skip_pager(not w.skip_pager) end
        elseif action == "minimize" then
            if w then w:minimize() end
        elseif action == "move_to_workspace" then
            local ws_num = tonumber(params[1])
            if w and ws_num then w:move_to_workspace(ws_num) end
        end

    elseif category == "workspace" then
        if action == "next" then
            self.workspaces:scroll_workspaces("right")
        elseif action == "prev" then
            self.workspaces:scroll_workspaces("left")
        elseif action == "toggle" then
            if ws then ws:toggle_visibility() end
        elseif tonumber(action) then
            self.workspaces:switch_to(tonumber(action))
        end

    elseif category == "layout" then
        if action == "next" then
            if ws then ws:next_layout()
            local ws2 = self.workspaces:get_current()
            if ws2 then ws2:arrange() end end
        elseif action == "prev" then
            if ws then ws:prev_layout()
            local ws2 = self.workspaces:get_current()
            if ws2 then ws2:arrange() end end
        elseif action == "incmaster" then
            self.master_count = self.master_count + 1
            if ws then
                ws.master_count = self.master_count
                ws:arrange()
            end
        elseif action == "decmaster" then
            self.master_count = math.max(1, self.master_count - 1)
            if ws then
                ws.master_count = self.master_count
                ws:arrange()
            end
        elseif action == "incmargin" then
            self.gap_size = self.gap_size + 2
            if ws then ws:arrange() end
        elseif action == "decmargin" then
            self.gap_size = math.max(0, self.gap_size - 2)
            if ws then ws:arrange() end
        elseif action == "swap_master" then
            if ws then ws:swap_master() end
        elseif action == "toggle_split" then
            self.layout_split_vertical = not self.layout_split_vertical
            if ws then ws:arrange() end
        elseif action == "resize" then
            if ws then ws:arrange() end
        elseif action == "shuffle" then
            if ws then ws:arrange() end
        elseif action == "info" then
            if ws then
                local names = layout.list_layout_names()
                local idx = ws.layout_index
                print("Layout: " .. (names[idx] or "unknown") ..
                      " | Windows: " .. #ws.windows ..
                      " | Master: " .. ws.master_count)
            end
        elseif action == "fullscreen" then
            if ws then ws:set_layout("monocle") end
        elseif action == "floating" then
            if w then w:toggle_floating() end
        elseif action == "toggle" then
            if ws then ws:arrange() end
        end

    elseif category == "reload" then
        self:reload_config()

    elseif category == "restart" then
        self:restart()

    elseif category == "exit" then
        self:exit()

    elseif category == "bar" then
        if action == "toggle" then
        end
        if action == "reload" then
        end
    end

    return true
end

function wm:update_active_window(window_id)
    X11.set_current_desktop(self.workspaces.current_ws - 1)
    self.workspaces:sync_ewmh()
end

function wm:reload_config()
    self.config_reload_pending = true
    local new_config, err = config.load(self.config_path)
    if new_config then
        self.config = new_config
        self.gap_size = new_config.gap_size or 0
        self.border_width = new_config.border_width or 2
        self.border_focus = new_config.colors.border_focus or new_config.border_focus or "#589cc9"
        self.border_unfocus = new_config.colors.border_unfocus or new_config.border_unfocus or "#333333"

        hook.fire("config_reload_pre")
        self:setup_keybindings()
        layout.load_builtin(self.base_path)
        layout.load_user_layouts(self.base_path, self.config)

        for _, ws in ipairs(self.workspaces:get_all()) do
            if ws then ws:arrange() end
        end

        hook.fire("config_reload_post")
        self.config_reload_pending = false
    else
        if err then
            print("[f3n2wm] Config reload failed: " .. err)
        end
    end
end

function wm:restart()
    self.running = false
    self.is_exiting = true
    local luajit_path = os.getenv("LUAJIT_PATH") or "luajit"
    local cmd = string.format("%s %s/init.lua %s &", luajit_path, self.base_path, self.base_path)
    X11.close_display()
    os.execute(cmd)
    os.exit(0)
end

function wm:exit()
    self.running = false
    self.is_exiting = true
    self.ipc.shutdown()
    local ws = self.workspaces:get_current()
    if ws then
        for _, wid in ipairs(ws.windows) do
            if wid then self.x11.unmap_window(wid) end
        end
    end
    self.x11.close_display()
    os.exit(0)
end

function wm:spawn_autostart()
    if self.config.exec then
        for _, cmd in ipairs(self.config.exec) do
            os.execute(cmd)
        end
    end
end

function wm:handle_map_request(event)
    local win_id = tonumber(event.xmaprequest.window)
    if not win_id then return end

    local attrs = X11.get_window_attributes(win_id)
    if attrs and attrs.override_redirect then return end

    local win_type = X11.get_window_type(win_id)
    if win_type == "desktop" or win_type == "dock" then
        X11.select_input(win_id, 0x00040000)
        X11.map_window(win_id)
        return
    end

    if window.is_registered(win_id) then return end

    local w = window.register(win_id)
    w.initializing = true

    local wm_name = X11.get_window_name(win_id)
    if wm_name then w.name = wm_name end

    local class_hint = X11.get_class_hint(win_id)
    if class_hint then
        w.class = class_hint.class
        w.instance = class_hint.name
    end

    w.pid = X11.get_wm_pid(win_id)
    w.transient_for = X11.get_transient_for(win_id)

    if win_type == "dialog" or win_type == "utility" or win_type == "splash" or
       win_type == "dropdown_menu" or win_type == "popup_menu" or win_type == "tooltip" then
        w.floating = true
    end

    for _, rule in ipairs(self.config.rules or {}) do
        local match_str = rule.match or ""
        local class_str = (w.class or "") .. " " .. (w.instance or "")
        if class_str:find(match_str, 1, true) then
            if rule.workspace then
                local target_ws = tonumber(rule.workspace)
                if target_ws then
                    w.workspace = self.workspaces:get_by_index(target_ws)
                end
            end
            if rule.float ~= nil then
                w.floating = rule.float
            end
            if rule.sticky ~= nil then
                w.sticky = rule.sticky
            end
            if rule.above ~= nil then
                w.above = rule.above
            end
        end
    end

    if w.floating then
        w.tiled = false
    else
        w.tiled = true
    end

    local wm_delete = X11.intern_atom("WM_DELETE_WINDOW")
    local take_focus = X11.intern_atom("WM_TAKE_FOCUS")
    X11.set_wm_protocols(win_id, {wm_delete, take_focus})

    X11.select_input(win_id, bit.bor(0x00000001, 0x00000002, 0x00000004,
        0x00000008, 0x00000010, 0x00000020, 0x00000040,
        0x00040000, 0x00008000))

    local current_ws = self.workspaces:get_current()
    if current_ws then
        current_ws:add_window(win_id)
        w.workspace = current_ws
    end

    X11.set_window_border_width(win_id, self.border_width)

    local focus_color = X11.alloc_color(self.border_focus)
    X11.set_window_border(win_id, focus_color)
    w.border_pixel = focus_color

    local geom = X11.get_window_geometry(win_id)
    if geom then
        w:update_geometry(geom.x, geom.y, geom.width, geom.height)
    end

    hook.fire("window_open_pre", w)

    if hook.fire("window_open", w) ~= false then
        X11.map_window(win_id)
        w.mapped = true
        w.visible = true

        local ws = self.workspaces:get_current()

        if self.config.focus_follows_mouse then
            self:focus_window(win_id)
        else
            if ws then ws:focus_window(win_id) end
        end

        if ws then ws:arrange() end

        hook.fire("window_open_post", w)
        w.initializing = false
    end
end

function wm:focus_window(win_id)
    local ws = self.workspaces:get_current()
    if ws then
        ws:focus_window(win_id)
    end
end

function wm:handle_unmap_notify(event)
    local win_id = tonumber(event.xunmap.window)
    if not win_id then return end
    if not window.is_registered(win_id) then return end

    local w = window.get(win_id)
    if not w then return end

    w.mapped = false
    w.visible = false
    w.focused = false

    local ws = w.workspace
    if ws then
        ws:remove_window(win_id)
        ws:arrange()
    end

    hook.fire("window_close", w, ws)
end

function wm:handle_destroy_notify(event)
    local win_id = tonumber(event.xany.window)
    if not win_id then return end
    if not window.is_registered(win_id) then return end

    local w = window.get(win_id)
    if not w then
        window.unregister(win_id)
        return
    end

    local ws = w.workspace
    window.unregister(win_id)

    if ws then
        ws:remove_window(win_id)
        ws:arrange()
    end

    hook.fire("window_destroy", w, ws)
end

function wm:handle_configure_request(event)
    local win_id = tonumber(event.xconfigurerequest.window)
    if not win_id then return end

    local w = window.get(win_id)
    if w and (w.floating or w.fullscreen) then
        local x = tonumber(event.xconfigurerequest.x) or w.x or 0
        local y = tonumber(event.xconfigurerequest.y) or w.y or 0
        local width = tonumber(event.xconfigurerequest.width) or w.width or 1
        local height = tonumber(event.xconfigurerequest.height) or w.height or 1
        if width > 0 and height > 0 then
            X11.move_resize_window(win_id, x, y, width, height)
        end
        return
    end

    if w then
        local ws = w.workspace
        if ws then ws:arrange() end
    end
end

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
        self.commands.execute(self, command, event)
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

function wm:handle_client_message(event)
    local win_id = tonumber(event.xclient.window)
    local msg_type = tonumber(event.xclient.message_type)
    local data0 = tonumber(event.xclient.data.l[0])
    local data1 = tonumber(event.xclient.data.l[1])

    if msg_type == X11.intern_atom("WM_PROTOCOLS") then
        if data0 == X11.intern_atom("WM_DELETE_WINDOW") then
            local w = window.get(win_id)
            if w then
                w:close()
            end
        elseif data0 == X11.intern_atom("WM_TAKE_FOCUS") then
        end
    elseif msg_type == X11.intern_atom("_NET_WM_STATE") then
        local action = data0
        local state_atom = data1
        if action == 1 or action == 2 then
            X11.add_wm_state(win_id, state_atom)
        elseif action == 0 then
            X11.remove_wm_state(win_id, state_atom)
        end
        self:handle_wm_state_change(win_id)
    elseif msg_type == X11.intern_atom("_NET_ACTIVE_WINDOW") then
        if win_id and win_id ~= 0 then
            self:focus_window(win_id)
        end
    end
end

function wm:handle_wm_state_change(win_id)
    local w = window.get(win_id)
    if not w then return end

    local state = X11.get_wm_state_atoms(win_id)
    local states = {}
    for _, atom in ipairs(state) do
        local name = X11.get_atom_name(atom)
        if name then states[name] = true end
    end

    w.maximized_h = states["_NET_WM_STATE_MAXIMIZED_VERT"]
    w.maximized_v = states["_NET_WM_STATE_MAXIMIZED_HORZ"]
    w.fullscreen = states["_NET_WM_STATE_FULLSCREEN"]
    w.sticky = states["_NET_WM_STATE_STICKY"]
    w.above = states["_NET_WM_STATE_ABOVE"]
    w.below = states["_NET_WM_STATE_BELOW"]
    w.skip_taskbar = states["_NET_WM_STATE_SKIP_TASKBAR"]
    w.skip_pager = states["_NET_WM_STATE_SKIP_PAGER"]

    local ws = self.workspaces:get_current()
    if ws then ws:arrange() end
end

function wm:handle_property_notify(event)
    local win_id = tonumber(event.xproperty.window)
    local atom = tonumber(event.xproperty.atom)
    hook.fire("property_change", win_id, atom)
end

function wm:handle_mapping_notify(event)
    X11.libs.x11.XRefreshKeyboardMapping(ffi.cast("XEvent*", event))
    self:setup_keybindings()
end

function wm:handle_configure_notify(event)
    local win_id = tonumber(event.xconfigure.window)
    local w = window.get(win_id)
    if w then
        w:update_geometry(
            tonumber(event.xconfigure.x),
            tonumber(event.xconfigure.y),
            tonumber(event.xconfigure.width),
            tonumber(event.xconfigure.height)
        )
    end
end

function wm:load_user_config()
    local user_config_path = os.getenv("HOME") .. "/.config/f3n2wm/f3n2wm.toml"
    local ok, result = pcall(toml.load, user_config_path)
    if ok and result then
        local merged = config.merge_tables(config.defaults, result)
        merged._path = user_config_path
        return merged
    end
    return nil
end

function wm:startup()
    hook.set_context(self)
    self.config = config.load(self.config_path)
    if not self.config then
        self.config = config.deep_copy(config.defaults)
        self.config._path = self.config_path
    end

    local user_config = self:load_user_config()
    if user_config then
        self.config = config.merge_tables(self.config, user_config)
    end

    X11.init(self.config.workspaces.count)

    window.set_wm(self)
    workspace_mod.set_wm(self)

    self.screen_width, self.screen_height = X11.get_screen_size()
    self.gap_size = self.config.gap_size or 0
    self.border_width = self.config.border_width or 2
    self.border_focus = self.config.colors.border_focus or
        self.config.border_focus or "#589cc9"
    self.border_unfocus = self.config.colors.border_unfocus or
        self.config.border_unfocus or "#333333"
    self.master_count = self.config.layout_options and
        self.config.layout_options.master_count or 1
    self.master_ratio = self.config.layout_options and
        self.config.layout_options.master_ratio or 0.5

    layout.load_builtin(self.base_path)
    layout.load_user_layouts(self.base_path, self.config)

    self.workspaces = workspace_mod.WorkspaceManager:new(self)
    self.workspaces:init()

    self.ipc.set_wm(self)
    self.ipc.init(self.config, self.base_path)

    self:setup_keybindings()

    hook.fire("init")

    local focus_color = X11.alloc_color(self.border_focus)
    local unfocus_color = X11.alloc_color(self.border_unfocus)

    self:spawn_autostart()

    hook.fire("startup")

    self:grab_server_and_sync()
end

function wm:grab_server_and_sync()
    X11.ungrab_server()
    X11.sync()
end

function wm:run()
    self.running = true

    while self.running do
        local event = ffi.new("XEvent")
        X11.next_event(event)

        local etype = tonumber(event.type)

        local ok, err = pcall(function()
            if etype == 2 then
                self:handle_key_press(event)
            elseif etype == 3 then
                self:handle_key_release(event)
            elseif etype == 4 then
                self:handle_button_press(event)
            elseif etype == 5 then
                self:handle_button_release(event)
            elseif etype == 6 then
                self:handle_motion_notify(event)
            elseif etype == 7 then
                self:handle_enter_notify(event)
            elseif etype == 17 then
                self:handle_destroy_notify(event)
            elseif etype == 18 then
                self:handle_unmap_notify(event)
            elseif etype == 19 then
            elseif etype == 20 then
                self:handle_map_request(event)
            elseif etype == 22 then
                self:handle_configure_notify(event)
            elseif etype == 23 then
                self:handle_configure_request(event)
            elseif etype == 28 then
                self:handle_property_notify(event)
            elseif etype == 33 then
                self:handle_client_message(event)
            elseif etype == 34 then
                self:handle_mapping_notify(event)
            end
        end)

        if not ok then
            print("EVENT ERROR: " .. tostring(err))
        end

        local ok2, err2 = pcall(ipc.poll)
        if not ok2 then
            print("IPC ERROR: " .. tostring(err2))
        end

        if self.config_reload_pending then
            self.config_reload_pending = false
            local ws = self.workspaces:get_current()
            if ws then ws:arrange() end
        end

        if X11.display ~= nil then
            local ok3, err3 = pcall(X11.sync)
            if not ok3 then
                io.stderr:write("[f3n2wm] X11 sync error: " .. tostring(err3) .. "\n")
                self.running = false
            end
        else
            self.running = false
        end
    end
end

local ok, err = pcall(wm.startup, wm)
if not ok then
    io.stderr:write("[f3n2wm] Failed to start: " .. tostring(err) .. "\n")
    os.exit(1)
end

wm:run()