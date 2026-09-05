local registry = require("window.registry")

local object = {}

object.Window = {}
object.Window.__index = object.Window

function object.Window:new(id)
    local w = setmetatable({}, object.Window)
    w.id = id
    w.x = 0
    w.y = 0
    w.width = 0
    w.height = 0
    w.border_width = 0
    w.visible = false
    w.mapped = false
    w.focused = false
    w.floating = false
    w.maximized = false
    w.maximized_h = false
    w.maximized_v = false
    w.fullscreen = false
    w.minimized = false
    w.sticky = false
    w.above = false
    w.below = false
    w.urgent = false
    w.skip_taskbar = false
    w.skip_pager = false
    w.always_on_top = false
    w.decorations = true
    w.titlebars = false
    w.workspace = nil
    w.monitor = nil
    w.pid = nil
    w.class = nil
    w.name = nil
    w.instance = nil
    w.role = nil
    w.transient_for = nil
    w.modal = false
    w.hint = nil
    w.can_resize = true
    w.can_close = true
    w.can_maximize = true
    w.can_minimize = true
    w.can_fullscreen = true
    w.opacity = 1.0
    w.z_order = 0
    w.tiled = false
    w.initializing = true
    w.float_x = nil
    w.float_y = nil
    w.float_width = nil
    w.float_height = nil
    w.dragging = false
    w.resizing = false
    w.is_destroying = false
    w.is_swallowed = false
    w.border_pixel = 0
    w.has_border = true
    w.allowed_actions = {}
    return w
end

function object.Window:update_geometry(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function object.Window:get_geometry()
    return { x = self.x, y = self.y, width = self.width, height = self.height }
end

function object.Window:set_border(color_hex)
    local wm = registry.wm
    if not wm or not self.has_border then return end
    local X11 = wm.x11
    local pixel = X11.alloc_color(color_hex)
    X11.set_window_border_width(self.id, wm.config.border_width)
    X11.set_window_border(self.id, pixel)
    self.border_pixel = pixel
end

function object.Window:focus()
    if self.is_destroying then return end
    local wm = registry.wm
    if not wm then return end
    local X11 = wm.x11
    self.focused = true
    X11.set_input_focus(self.id)
    wm:update_active_window(self.id)
    local focus_color = wm.config.colors and wm.config.colors.border_focus or wm.config.border_focus
    self:set_border(focus_color)
    if wm.workspaces then
        local ws = wm.workspaces:get_current()
        if ws then ws:raise_window(self.id) end
    end
    wm.hooks.fire("window_focus", self, self.workspace)
end

function object.Window:unfocus()
    local wm = registry.wm
    if not wm then return end
    self.focused = false
    local unfocus_color = wm.config.colors and wm.config.colors.border_unfocus or wm.config.border_unfocus
    self:set_border(unfocus_color)
    wm.hooks.fire("window_unfocus", self, self.workspace)
end

function object.Window:map()
    local wm = registry.wm
    if not wm then return end
    self.mapped = true
    self.visible = true
    wm.x11.map_window(self.id)
end

function object.Window:unmap()
    local wm = registry.wm
    if not wm then return end
    self.mapped = false
    self.visible = false
    wm.x11.unmap_window(self.id)
end

function object.Window:close()
    local wm = registry.wm
    if not wm then return end
    local X11 = wm.x11
    self.is_destroying = true
    local wm_delete = X11.intern_atom("WM_DELETE_WINDOW")
    local protocols = X11.get_wm_protocols(self.id)
    local has_delete = false
    for _, p in ipairs(protocols) do
        if p == wm_delete then has_delete = true break end
    end
    if has_delete then
        X11.send_client_message(self.id, X11.intern_atom("WM_PROTOCOLS"), wm_delete)
    else
        X11.destroy_window(self.id)
    end
    registry.unregister(self.id)
end

function object.Window:kill()
    local wm = registry.wm
    if not wm then return end
    wm.x11.destroy_window(self.id)
    registry.unregister(self.id)
end

return object