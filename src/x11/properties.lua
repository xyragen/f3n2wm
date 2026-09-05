local properties = {}

function properties.get_window_attributes(X11, window)
    local attrs = ffi.new("XWindowAttributes")
    local result = X11.libs.x11.XGetWindowAttributes(X11.display, window, attrs)
    if result == 0 then return nil end
    return {
        x = tonumber(attrs.x), y = tonumber(attrs.y),
        width = tonumber(attrs.width), height = tonumber(attrs.height),
        border_width = tonumber(attrs.border_width),
        override_redirect = tonumber(attrs.override_redirect),
    }
end

function properties.get_window_geometry(X11, window)
    local root = ffi.new("Window[1]")
    local child = ffi.new("Window[1]")
    local x = ffi.new("int[1]"); local y = ffi.new("int[1]")
    local w = ffi.new("unsigned int[1]"); local h = ffi.new("unsigned int[1]")
    local b = ffi.new("unsigned int[1]"); local d = ffi.new("unsigned int[1]")
    local result = X11.libs.x11.XGetGeometry(X11.display, window, root, x, y, w, h, b, d)
    if result == 0 then return nil end
    return {
        x = tonumber(x[0]), y = tonumber(y[0]),
        width = tonumber(w[0]), height = tonumber(h[0]),
    }
end

function properties.get_wm_protocols(X11, window)
    local prop = X11.get_property(window, X11.intern_atom("WM_PROTOCOLS"), X11.intern_atom("ATOM"), 1000000)
    if not prop or prop.format ~= 32 then return {} end
    local arr = ffi.cast("uint32_t*", prop.data)
    local protocols = {}
    for i = 0, prop.nitems - 1 do protocols[i+1] = tonumber(arr[i]) end
    X11.libs.x11.XFree(prop.data)
    return protocols
end

function properties.get_window_name(X11, window)
    local text_prop = ffi.new("XTextProperty")
    local result = X11.libs.x11.XGetWMName(X11.display, window, text_prop)
    if result == 0 then return nil end
    return ffi.string(text_prop.value)
end

function properties.get_wm_pid(X11, window)
    local prop = X11.get_property(window, X11.intern_atom("_NET_WM_PID"), X11.intern_atom("CARDINAL"), 4)
    if not prop or prop.format ~= 32 then return nil end
    local val = ffi.cast("uint32_t*", prop.data)[0]
    X11.libs.x11.XFree(prop.data)
    return tonumber(val)
end

function properties.get_transient_for(X11, window)
    local prop = X11.get_property(window, X11.intern_atom("WM_TRANSIENT_FOR"), X11.intern_atom("WINDOW"), 1)
    if not prop or prop.format ~= 32 then return nil end
    local val = ffi.cast("uint32_t*", prop.data)[0]
    X11.libs.x11.XFree(prop.data)
    return tonumber(val)
end

function properties.get_class_hint(X11, window)
    local hints = ffi.new("XClassHint")
    local result = X11.libs.x11.XGetClassHint(X11.display, window, hints)
    if result == 0 then return nil end
    local res = {}
    if hints.res_name ~= nil then
        res.name = ffi.string(hints.res_name)
        X11.libs.x11.XFree(hints.res_name)
    end
    if hints.res_class ~= nil then
        res.class = ffi.string(hints.res_class)
        X11.libs.x11.XFree(hints.res_class)
    end
    return res
end

function properties.get_normal_hints(X11, window)
    local p = X11.libs.x11.XAllocSizeHints()
    local wmh = ffi.cast("XSizeHints*", p)
    local result = X11.libs.x11.XGetWMNormalHints(X11.display, window, wmh, ffi.new("long[1]"))
    if result == 0 then X11.libs.x11.XFree(p) return nil end
    local hints = {
        min_width = tonumber(wmh.min_width), min_height = tonumber(wmh.min_height),
        max_width = tonumber(wmh.max_width), max_height = tonumber(wmh.max_height),
        base_width = tonumber(wmh.base_width), base_height = tonumber(wmh.base_height),
        width_inc = tonumber(wmh.width_inc), height_inc = tonumber(wmh.height_inc),
        flags = tonumber(wmh.flags),
    }
    X11.libs.x11.XFree(p)
    return hints
end

function properties.get_wm_hints(X11, window)
    local p = X11.libs.x11.XAllocWMHints()
    local hints = ffi.cast("XWMHints*", p)
    local result = X11.libs.x11.XGetWMHints(X11.display, window, hints)
    if result == 0 then X11.libs.x11.XFree(p) return nil end
    local h = { flags = tonumber(hints.flags), input = tonumber(hints.input) }
    X11.libs.x11.XFree(p)
    return h
end

return properties