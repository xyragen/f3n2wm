local bit = require("bit")

local ewmh = {}

function ewmh.init_atoms(X11)
    local atoms = {
        "WM_NAME","WM_ICON_NAME","WM_NORMAL_HINTS","WM_PROTOCOLS",
        "WM_TRANSIENT_FOR","WM_STATE","WM_HINTS","WM_CLIENT_MACHINE",
        "WM_DELETE_WINDOW","WM_TAKE_FOCUS","WM_COLORMAP_WINDOWS",
        "_NET_SUPPORTED","_NET_CLIENT_LIST","_NET_CLIENT_LIST_STACKING",
        "_NET_NUMBER_OF_DESKTOP","_NET_DESKTOP_NAMES","_NET_ACTIVE_WINDOW",
        "_NET_WORKAREA","_NET_CURRENT_DESKTOP","_NET_DESKTOP_VIEWPORT",
        "_NET_VIRTUAL_ROOTS","_NET_DESKTOP_LAYOUT","_NET_SHOWING_DESKTOP",
        "_NET_WM_WINDOW_TYPE","_NET_WM_STATE","_NET_WM_DESKTOP",
        "_NET_WM_ALLOWED_ACTIONS","_NET_WM_STRUT","_NET_WM_STRUT_PARTIAL",
        "_NET_WM_PID","_NET_WM_SYNC_REQUEST","_NET_WM_MOVERESIZE",
        "_NET_WM_STATE_MODAL","_NET_WM_STATE_STICKY",
        "_NET_WM_STATE_MAXIMIZED_VERT","_NET_WM_STATE_MAXIMIZED_HORZ",
        "_NET_WM_STATE_SHADED","_NET_WM_STATE_SKIP_TASKBAR",
        "_NET_WM_STATE_SKIP_PAGER","_NET_WM_STATE_HIDDEN",
        "_NET_WM_STATE_FULLSCREEN","_NET_WM_STATE_ABOVE","_NET_WM_STATE_BELOW",
        "_NET_WM_STATE_DEMANDS_ATTENTION","_NET_WM_WINDOW_TYPE_DOCK",
        "_NET_WM_WINDOW_TYPE_DESKTOP","_NET_WM_WINDOW_TYPE_MENU",
        "_NET_WM_WINDOW_TYPE_SPLASH","_NET_WM_WINDOW_TYPE_DIALOG",
        "_NET_WM_WINDOW_TYPE_UTILITY","_NET_WM_WINDOW_TYPE_TOOLBAR",
        "_NET_WM_WINDOW_TYPE_NORMAL","_NET_WM_WINDOW_TYPE_NOTIFICATION",
        "UTF8_STRING","STRING","ATOM","CARDINAL","WINDOW",
    }
    for _, name in ipairs(atoms) do
        X11.intern_atom(name)
    end
end

function ewmh.get_active_window(X11)
    local prop = X11.get_property(X11.root, X11.intern_atom("_NET_ACTIVE_WINDOW"), X11.intern_atom("WINDOW"), 1)
    if not prop or prop.format ~= 32 then return nil end
    local val = ffi.cast("uint32_t*", prop.data)[0]
    X11.libs.x11.XFree(prop.data)
    return tonumber(val)
end

function ewmh.set_active_window(X11, window)
    X11.libs.x11.XSetInputFocus(X11.display, window, 0, 0)
end

function ewmh.get_current_desktop(X11)
    local prop = X11.get_property(X11.root, X11.intern_atom("_NET_CURRENT_DESKTOP"), X11.intern_atom("CARDINAL"), 1)
    if not prop or prop.format ~= 32 then return 0 end
    local val = ffi.cast("uint32_t*", prop.data)[0]
    X11.libs.x11.XFree(prop.data)
    return tonumber(val)
end

function ewmh.set_current_desktop(X11, desktop)
    local data = ffi.new("uint32_t[1]", desktop)
    X11.change_property(X11.root, X11.intern_atom("_NET_CURRENT_DESKTOP"), X11.intern_atom("CARDINAL"), 32, data, 1)
end

function ewmh.get_desktop_names(X11)
    local prop = X11.get_property(X11.root, X11.intern_atom("_NET_DESKTOP_NAMES"), X11.intern_atom("STRING"), 1000000)
    if not prop or prop.format ~= 8 then return {} end
    local str = ffi.string(prop.data, prop.nitems)
    X11.libs.x11.XFree(prop.data)
    local names = {}
    for name in str:gmatch("([^%z]+)") do names[#names+1] = name end
    return names
end

function ewmh.set_desktop_names(X11, names)
    local str = table.concat(names, "\0") .. "\0"
    local data = ffi.new("char[?]", #str)
    ffi.copy(data, str)
    X11.change_property(X11.root, X11.intern_atom("_NET_DESKTOP_NAMES"), X11.intern_atom("STRING"), 8, data, #str)
end

function ewmh.set_client_list(X11, windows)
    if #windows == 0 then return end
    local arr = ffi.new("uint32_t[?]", #windows)
    for i, w in ipairs(windows) do arr[i-1] = w end
    X11.change_property(X11.root, X11.intern_atom("_NET_CLIENT_LIST"), X11.intern_atom("WINDOW"), 32, ffi.cast("char*", arr), #windows)
end

function ewmh.set_client_list_stacking(X11, windows)
    if #windows == 0 then return end
    local arr = ffi.new("uint32_t[?]", #windows)
    for i, w in ipairs(windows) do arr[i-1] = w end
    X11.change_property(X11.root, X11.intern_atom("_NET_CLIENT_LIST_STACKING"), X11.intern_atom("WINDOW"), 32, ffi.cast("char*", arr), #windows)
end

function ewmh.set_workarea(X11, rects)
    local count = #rects
    local data = ffi.new("uint32_t[?]", 4 * count)
    for i, r in ipairs(rects) do
        local off = (i - 1) * 4
        data[off + 0] = r.x; data[off + 1] = r.y
        data[off + 2] = r.width; data[off + 3] = r.height
    end
    X11.change_property(X11.root, X11.intern_atom("_NET_WORKAREA"), X11.intern_atom("CARDINAL"), 32, data, 4 * count)
end

function ewmh.get_wm_state_atoms(X11, window)
    local prop = X11.get_property(window, X11.intern_atom("_NET_WM_STATE"), X11.intern_atom("ATOM"), 1000000)
    if not prop or prop.format ~= 32 then return {} end
    local arr = ffi.cast("uint32_t*", prop.data)
    local state = {}
    for i = 0, prop.nitems - 1 do state[i+1] = tonumber(arr[i]) end
    X11.libs.x11.XFree(prop.data)
    return state
end

function ewmh.add_wm_state(X11, window, state_atom)
    local msg = ffi.new("XClientMessageEvent")
    msg.type = 33; msg.window = window
    msg.message_type = X11.intern_atom("_NET_WM_STATE")
    msg.format = 32; msg.data.l[0] = 1; msg.data.l[1] = state_atom
    local event = ffi.new("XEvent")
    ffi.copy(event, msg, ffi.sizeof("XClientMessageEvent"))
    X11.libs.x11.XSendEvent(X11.display, X11.root, 0, 0x00020000, ffi.cast("XEvent*", event))
end

function ewmh.remove_wm_state(X11, window, state_atom)
    local msg = ffi.new("XClientMessageEvent")
    msg.type = 33; msg.window = window
    msg.message_type = X11.intern_atom("_NET_WM_STATE")
    msg.format = 32; msg.data.l[0] = 0; msg.data.l[1] = state_atom
    local event = ffi.new("XEvent")
    ffi.copy(event, msg, ffi.sizeof("XClientMessageEvent"))
    X11.libs.x11.XSendEvent(X11.display, X11.root, 0, 0x00020000, ffi.cast("XEvent*", event))
end

function ewmh.toggle_wm_state(X11, window, state_atom)
    local msg = ffi.new("XClientMessageEvent")
    msg.type = 33; msg.window = window
    msg.message_type = X11.intern_atom("_NET_WM_STATE")
    msg.format = 32; msg.data.l[0] = 2; msg.data.l[1] = state_atom
    local event = ffi.new("XEvent")
    ffi.copy(event, msg, ffi.sizeof("XClientMessageEvent"))
    X11.libs.x11.XSendEvent(X11.display, X11.root, 0, 0x00020000, ffi.cast("XEvent*", event))
end

function ewmh.get_window_type(X11, window)
    local prop = X11.get_property(window, X11.intern_atom("_NET_WM_WINDOW_TYPE"), X11.intern_atom("ATOM"), 1000000)
    if not prop or prop.nitems == 0 then return "normal" end
    local arr = ffi.cast("uint32_t*", prop.data)
    local types = {}
    for i = 0, prop.nitems - 1 do
        local atom = tonumber(arr[i])
        local name = X11.get_atom_name(atom)
        if name then types[name] = true end
    end
    X11.libs.x11.XFree(prop.data)
    if types["_NET_WM_WINDOW_TYPE_DESKTOP"] then return "desktop"
    elseif types["_NET_WM_WINDOW_TYPE_DOCK"] then return "dock"
    elseif types["_NET_WM_WINDOW_TYPE_MENU"] then return "menu"
    elseif types["_NET_WM_WINDOW_TYPE_SPLASH"] then return "splash"
    elseif types["_NET_WM_WINDOW_TYPE_DIALOG"] then return "dialog"
    elseif types["_NET_WM_WINDOW_TYPE_UTILITY"] then return "utility"
    elseif types["_NET_WM_WINDOW_TYPE_TOOLBAR"] then return "toolbar"
    elseif types["_NET_WM_WINDOW_TYPE_NOTIFICATION"] then return "notification"
    end
    return "normal"
end

function ewmh.xinerama_query_screens(X11)
    if not X11.libs.xinerama then return {X11.get_screen_rect()} end
    local count_ptr = ffi.new("int[1]")
    local info_ptr = X11.libs.xinerama.XineramaQueryScreens(X11.display, count_ptr)
    if info_ptr == nil then return {X11.get_screen_rect()} end
    local screens = {}
    local count = count_ptr[0]
    for i = 0, count - 1 do
        local info = info_ptr[i]
        screens[#screens + 1] = {
            x = tonumber(info.x_org), y = tonumber(info.y_org),
            width = tonumber(info.width), height = tonumber(info.height),
        }
    end
    X11.libs.x11.XFree(info_ptr)
    return screens
end

function ewmh.xinerama_is_active(X11)
    if not X11.libs.xinerama then return false end
    return X11.libs.xinerama.XineramaIsActive(X11.display) ~= 0
end

return ewmh