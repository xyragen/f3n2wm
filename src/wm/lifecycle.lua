local ffi = require("ffi")
local X11 = require("x11")
local config_mod = require("config")
local hook = require("hook")
local window = require("window")
local workspace_mod = require("workspace")
local layout = require("layout")
local ipc = require("ipc")
local debug = require("debug")

local lifecycle = {}

function lifecycle.install(wm)
    function wm:update_active_window(window_id)
        X11.set_current_desktop(self.workspaces.current_ws - 1)
        self.workspaces:sync_ewmh()
    end

    function wm:reload_config()
        self.config_reload_pending = true
        local new_config = config_mod.load(self.base_path, self.config_dir or (os.getenv("HOME") .. "/.config/f3n2wm"))
        if new_config then
            self.config = new_config
            self.gap_size = new_config.gap_size or 0
            self.border_width = new_config.border_width or 2
            self.border_focus = (new_config.colors and new_config.colors.border_focus) or new_config.border_focus or "#589cc9"
            self.border_unfocus = (new_config.colors and new_config.colors.border_unfocus) or new_config.border_unfocus or "#333333"

            hook.fire("config_reload_pre")
            self:setup_keybindings()
            layout.load_builtin(self.base_path)
            layout.load_user_layouts(self.base_path, self.config)

            for _, ws in ipairs(self.workspaces:get_all()) do
                if ws then ws:arrange() end
            end

            hook.fire("config_reload_post")
            self.config_reload_pending = false
            debug.info("wm", "config reloaded")
        else
            debug.warn("wm", "config reload returned nil")
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
        debug.close()
        os.exit(0)
    end

    function wm:spawn_autostart()
        if self.config.exec then
            for _, cmd in ipairs(self.config.exec) do
                os.execute(cmd)
            end
        end
    end

    function wm:focus_window(win_id)
        local ws = self.workspaces:get_current()
        if ws then ws:focus_window(win_id) end
    end

    function wm:startup()
        hook.set_context(self)
        self.config = config_mod.load(self.base_path, self.config_dir or (os.getenv("HOME") .. "/.config/f3n2wm"))
        if not self.config then
            debug.error("wm", "failed to load config")
            error("failed to load config")
        end

        debug.configure(self.config.debugging or {})
        debug.info("wm", "config loaded")

        window.set_wm(self)
        workspace_mod.set_wm(self)

        X11.init(self.config.workspaces and self.config.workspaces.count or 10)

        self.screen_width, self.screen_height = X11.get_screen_size()
        self.gap_size = self.config.gap_size or 0
        self.border_width = self.config.border_width or 2
        self.border_focus = (self.config.colors and self.config.colors.border_focus) or self.config.border_focus or "#589cc9"
        self.border_unfocus = (self.config.colors and self.config.colors.border_unfocus) or self.config.border_unfocus or "#333333"
        self.master_count = self.config.layout_options and self.config.layout_options.master_count or 1
        self.master_ratio = self.config.layout_options and self.config.layout_options.master_ratio or 0.5

        layout.load_builtin(self.base_path)
        layout.load_user_layouts(self.base_path, self.config)
        debug.info("wm", "layouts loaded: " .. table.concat(layout.list_layout_names(), ", "))

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
        debug.info("wm", "startup complete")
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
                if etype == 2 then self:handle_key_press(event)
                elseif etype == 3 then self:handle_key_release(event)
                elseif etype == 4 then self:handle_button_press(event)
                elseif etype == 5 then self:handle_button_release(event)
                elseif etype == 6 then self:handle_motion_notify(event)
                elseif etype == 7 then self:handle_enter_notify(event)
                elseif etype == 17 then self:handle_destroy_notify(event)
                elseif etype == 18 then self:handle_unmap_notify(event)
                elseif etype == 20 then self:handle_map_request(event)
                elseif etype == 22 then self:handle_configure_notify(event)
                elseif etype == 23 then self:handle_configure_request(event)
                elseif etype == 28 then self:handle_property_notify(event)
                elseif etype == 33 then self:handle_client_message(event)
                elseif etype == 34 then self:handle_mapping_notify(event)
                end
            end)

            if not ok then
                debug.error("event", "type=" .. tostring(etype) .. " error=" .. tostring(err))
            end

            local ok2, err2 = pcall(ipc.poll)
            if not ok2 then
                debug.error("ipc", tostring(err2))
            end

            if self.config_reload_pending then
                self.config_reload_pending = false
                local ws = self.workspaces:get_current()
                if ws then ws:arrange() end
            end

            if X11.display ~= nil then
                local ok3, err3 = pcall(X11.sync)
                if not ok3 then
                    debug.error("x11", "sync error: " .. tostring(err3))
                    self.running = false
                end
            else
                self.running = false
            end
        end
    end
end

return lifecycle