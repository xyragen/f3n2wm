local bit = require("bit")
local ffi = require("ffi")
local X11 = require("x11")
local hook = require("hook")
local window = require("window")

local window_events = {}

function window_events.install(wm)
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
end

return window_events