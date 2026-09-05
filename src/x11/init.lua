local ffi = require("ffi")
local bit = require("bit")
local debug = require("debug")

local display = require("x11.display")
local ewmh = require("x11.ewmh")
local properties = require("x11.properties")

ffi.cdef(display.cdef)
ffi.cdef(display.cdef_xinerama)

local X11 = {
    libs = {},
    atoms = {},
    display = nil,
    root = nil,
    screen_number = 0,
}

function X11.load_libs()
    local ok, err = pcall(function() X11.libs.x11 = ffi.load("X11") end)
    if not ok then error("Failed to load libX11: " .. tostring(err)) end
    pcall(function() X11.libs.xinerama = ffi.load("Xinerama") end)
end

function X11.open_display(display_name)
    local cstr
    if display_name then
        cstr = ffi.new("char[?]", #display_name + 1)
        ffi.copy(cstr, display_name)
    else
        cstr = ffi.cast("const char*", nil)
    end
    X11.display = X11.libs.x11.XOpenDisplay(cstr)
    if X11.display == nil then error("Cannot open display") end
    X11.screen_number = X11.libs.x11.XDefaultScreen(X11.display)
    X11.root = X11.libs.x11.XDefaultRootWindow(X11.display)
    return X11.display
end

function X11.close_display()
    if X11.display then
        X11.libs.x11.XCloseDisplay(X11.display)
        X11.display = nil
    end
end

function X11.get_screen_size()
    local w = X11.libs.x11.XDisplayWidth(X11.display, X11.screen_number)
    local h = X11.libs.x11.XDisplayHeight(X11.display, X11.screen_number)
    return tonumber(w), tonumber(h)
end

function X11.get_screen_rect()
    local w = X11.libs.x11.XDisplayWidth(X11.display, X11.screen_number)
    local h = X11.libs.x11.XDisplayHeight(X11.display, X11.screen_number)
    return { x = 0, y = 0, width = tonumber(w), height = tonumber(h) }
end

function X11.intern_atom(name, only_if_exists)
    local atom = X11.atoms[name]
    if atom then return atom end
    if only_if_exists == nil then only_if_exists = 1 end
    local cstr = ffi.new("char[?]", #name + 1)
    ffi.copy(cstr, name)
    atom = X11.libs.x11.XInternAtom(X11.display, cstr, only_if_exists)
    X11.atoms[name] = atom
    return atom
end

function X11.get_atom_name(atom)
    local cstr = X11.libs.x11.XGetAtomName(X11.display, atom)
    if cstr == nil then return nil end
    local name = ffi.string(cstr)
    X11.libs.x11.XFree(cstr)
    return name
end

function X11.change_property(window, atom, atom_type, format, data, nelements)
    if type(data) == "cdata" then
        X11.libs.x11.XChangeProperty(X11.display, window, atom, atom_type, format, 1, data, nelements)
    else
        local buf = ffi.new("unsigned char[?]", #data)
        ffi.copy(buf, data, #data)
        X11.libs.x11.XChangeProperty(X11.display, window, atom, atom_type, format, 1, buf, nelements)
    end
end

function X11.get_property(window, atom, type_hint, max_length)
    local atype = ffi.new("unsigned long[1]")
    local aformat = ffi.new("int[1]")
    local nitems = ffi.new("unsigned long[1]")
    local bytes_after = ffi.new("unsigned long[1]")
    local data_ptr = ffi.new("unsigned char*[1]")
    max_length = max_length or 1000000
    local result = X11.libs.x11.XGetWindowProperty(X11.display, window, atom, 0, max_length, 0,
        type_hint or ffi.cast("unsigned long", 0), atype, aformat, nitems, bytes_after, data_ptr)
    if result ~= 0 then return nil end
    return { type = atype[0], format = aformat[0], nitems = nitems[0],
             bytes_after = bytes_after[0], data = data_ptr[0] }
end

function X11.send_client_message(window, message_type, data1, data2, data3, data4, data5)
    local msg = ffi.new("XClientMessageEvent")
    msg.type = 33; msg.window = window; msg.message_type = message_type; msg.format = 32
    msg.data.l[0] = data1 or 0; msg.data.l[1] = data2 or 0; msg.data.l[2] = data3 or 0
    msg.data.l[3] = data4 or 0; msg.data.l[4] = data5 or 0
    local event = ffi.new("XEvent")
    ffi.copy(event, msg, ffi.sizeof("XClientMessageEvent"))
    X11.libs.x11.XSendEvent(X11.display, X11.root, 0, 0x00020000, ffi.cast("XEvent*", event))
end

function X11.move_window(window, x, y) X11.libs.x11.XMoveWindow(X11.display, window, x, y) end
function X11.resize_window(window, width, height) X11.libs.x11.XResizeWindow(X11.display, window, width, height) end

function X11.move_resize_window(window, x, y, width, height)
    local changes = ffi.new("XWindowChanges")
    changes.x = x; changes.y = y; changes.width = width; changes.height = height; changes.border_width = 0
    local mask = bit.bor(0x0001, 0x0002, 0x0004, 0x0008)
    X11.libs.x11.XConfigureWindow(X11.display, window, mask, changes)
end

function X11.set_window_border(window, pixel) X11.libs.x11.XSetWindowBorder(X11.display, window, pixel) end
function X11.set_window_border_width(window, width) X11.libs.x11.XSetWindowBorderWidth(X11.display, window, width) end
function X11.map_window(window) X11.libs.x11.XMapWindow(X11.display, window) end
function X11.unmap_window(window) X11.libs.x11.XUnmapWindow(X11.display, window) end
function X11.raise_window(window) X11.libs.x11.XRaiseWindow(X11.display, window) end
function X11.lower_window(window) X11.libs.x11.XLowerWindow(X11.display, window) end
function X11.destroy_window(window) X11.libs.x11.XDestroyWindow(X11.display, window) end

function X11.select_input(window, event_mask) X11.libs.x11.XSelectInput(X11.display, window, event_mask) end

function X11.grab_key(window, keycode, modifiers) X11.libs.x11.XGrabKey(X11.display, keycode, modifiers, window, 0, 1, 0) end

function X11.grab_button(window, button, modifiers)
    X11.libs.x11.XGrabButton(X11.display, button, modifiers, window, 0,
        bit.bor(0x0001, 0x0002, 0x0004, 0x0008), 0, 0, 0, 0)
end

function X11.set_input_focus(window) X11.libs.x11.XSetInputFocus(X11.display, window, 0, 0) end

function X11.get_input_focus()
    local focus = ffi.new("Window[1]"); local revert = ffi.new("int[1]")
    X11.libs.x11.XGetInputFocus(X11.display, focus, revert)
    return tonumber(focus[0])
end

function X11.sync() X11.libs.x11.XSync(X11.display, 0) end
function X11.flush() X11.libs.x11.XFlush(X11.display) end
function X11.pending_events() return X11.libs.x11.XPending(X11.display) end
function X11.next_event(event) return X11.libs.x11.XNextEvent(X11.display, event) end

function X11.store_name(window, name)
    local cstr = ffi.new("char[?]", #name + 1)
    ffi.copy(cstr, name)
    X11.libs.x11.XStoreName(X11.display, window, cstr)
end

function X11.set_wm_protocols(window, protocols)
    local arr = ffi.new("Atom[?]", #protocols)
    for i, p in ipairs(protocols) do arr[i-1] = p end
    X11.libs.x11.XSetWMProtocols(X11.display, window, ffi.cast("Atom*", arr), #protocols)
end

function X11.delete_property(window, atom) X11.libs.x11.XDeleteProperty(X11.display, window, atom) end

function X11.parse_hex_color(hex)
    local r, g, b = hex:match("#(%x%x)(%x%x)(%x%x)")
    if not r then r, g, b = "00", "00", "00" end
    return tonumber(r, 16) / 255 * 65535, tonumber(g, 16) / 255 * 65535, tonumber(b, 16) / 255 * 65535
end

function X11.alloc_color(hex)
    local r, g, b = X11.parse_hex_color(hex)
    local cmap = X11.libs.x11.XDefaultColormap(X11.display, X11.screen_number)
    local color = ffi.new("XColor")
    color.red = r; color.green = g; color.blue = b
    local result = X11.libs.x11.XAllocColor(X11.display, cmap, color)
    if result == 0 then
        X11.libs.x11.XLookupColor(X11.display, cmap, hex, color, color)
        return tonumber(color.pixel)
    end
    return tonumber(color.pixel)
end

function X11.select_substructure_redirect(root)
    local mask = bit.bor(0x00100000, 0x00200000, 0x00040000,
        0x00000001, 0x00000002, 0x00000004, 0x00000008,
        0x00000010, 0x00000020, 0x00000040, 0x00020000)
    X11.libs.x11.XSelectInput(X11.display, root, mask)
end

function X11.get_pointer_position()
    local rr = ffi.new("Window[1]"); local cr = ffi.new("Window[1]")
    local x = ffi.new("int[1]"); local y = ffi.new("int[1]")
    local wx = ffi.new("int[1]"); local wy = ffi.new("int[1]")
    local mask = ffi.new("unsigned int[1]")
    local result = X11.libs.x11.XQueryPointer(X11.display, X11.root, rr, cr, x, y, wx, wy, mask)
    return { x = tonumber(x[0]), y = tonumber(y[0]), mask = tonumber(mask[0]), same_screen = result ~= 0 }
end

function X11.warp_pointer(dest_x, dest_y)
    X11.libs.x11.XWarpPointer(X11.display, ffi.cast("Window", 0), X11.root, 0, 0, 0, 0, dest_x, dest_y)
end

function X11.grab_pointer(window)
    return X11.libs.x11.XGrabPointer(X11.display, window, 0,
        bit.bor(0x0001, 0x0002, 0x0004, 0x0008), 0, 0, 0, 0, 0)
end

function X11.ungrab_pointer(time) X11.libs.x11.XUngrabPointer(X11.display, time or 0) end

function X11.get_modifier_map()
    local modmap = X11.libs.x11.XGetModifierMapping(X11.display)
    if modmap == nil then return {} end
    local maxkpm = tonumber(modmap.max_keypermod)
    local mods = {}
    for mod = 0, 7 do
        mods[mod+1] = {}
        local offset = mod * maxkpm
        for k = 0, maxkpm - 1 do
            local kc = tonumber(modmap.modifiermap[offset + k])
            if kc ~= 0 then mods[mod+1][#mods[mod+1] + 1] = kc end
        end
    end
    X11.libs.x11.XFreeModifiermap(modmap)
    return mods
end

function X11.get_keymap_info()
    local min_kc = ffi.new("int[1]"); local max_kc = ffi.new("int[1]")
    X11.libs.x11.XDisplayKeycodes(X11.display, min_kc, max_kc)
    return { min_keycode = tonumber(min_kc[0]), max_keycode = tonumber(max_kc[0]) }
end

function X11.keysym_to_keycode(keysym) return tonumber(X11.libs.x11.XKeysymToKeycode(X11.display, keysym)) end
function X11.keycode_to_keysym(keycode, index) return tonumber(X11.libs.x11.XKeycodeToKeysym(X11.display, keycode, index or 0)) end
function X11.grab_server() X11.libs.x11.XGrabServer(X11.display) end
function X11.ungrab_server() X11.libs.x11.XUngrabServer(X11.display) end
function X11.allow_events(mode, time) X11.libs.x11.XAllowEvents(X11.display, mode, time or 0) end

function X11.set_error_handler(callback)
    local fn = ffi.cast("int (*)(void*, void*)", function(display, error_ptr)
        local err = ffi.cast("XErrorEvent*", error_ptr)
        if callback then callback(tonumber(err.error_code), tonumber(err.request_code)) end
        return 0
    end)
    X11._error_handler = fn
    X11.libs.x11.XSetErrorHandler(fn)
end

function X11.create_font_cursor(shape) return X11.libs.x11.XCreateFontCursor(X11.display, shape or 0) end
function X11.define_cursor(window, cursor) X11.libs.x11.XDefineCursor(X11.display, window, cursor) end

function X11.init_atoms() ewmh.init_atoms(X11) end

function X11.get_window_attributes(window) return properties.get_window_attributes(X11, window) end
function X11.get_window_geometry(window) return properties.get_window_geometry(X11, window) end
function X11.get_wm_protocols(window) return properties.get_wm_protocols(X11, window) end
function X11.get_window_name(window) return properties.get_window_name(X11, window) end
function X11.get_wm_pid(window) return properties.get_wm_pid(X11, window) end
function X11.get_transient_for(window) return properties.get_transient_for(X11, window) end
function X11.get_class_hint(window) return properties.get_class_hint(X11, window) end
function X11.get_normal_hints(window) return properties.get_normal_hints(X11, window) end
function X11.get_wm_hints(window) return properties.get_wm_hints(X11, window) end

function X11.get_active_window() return ewmh.get_active_window(X11) end
function X11.set_active_window(window) ewmh.set_active_window(X11, window) end
function X11.get_current_desktop() return ewmh.get_current_desktop(X11) end
function X11.set_current_desktop(desktop) ewmh.set_current_desktop(X11, desktop) end
function X11.get_desktop_names() return ewmh.get_desktop_names(X11) end
function X11.set_desktop_names(names) ewmh.set_desktop_names(X11, names) end
function X11.set_client_list(windows) ewmh.set_client_list(X11, windows) end
function X11.set_client_list_stacking(windows) ewmh.set_client_list_stacking(X11, windows) end
function X11.set_workarea(rects) ewmh.set_workarea(X11, rects) end
function X11.get_wm_state_atoms(window) return ewmh.get_wm_state_atoms(X11, window) end
function X11.add_wm_state(window, state_atom) ewmh.add_wm_state(X11, window, state_atom) end
function X11.remove_wm_state(window, state_atom) ewmh.remove_wm_state(X11, window, state_atom) end
function X11.toggle_wm_state(window, state_atom) ewmh.toggle_wm_state(X11, window, state_atom) end
function X11.get_window_type(window) return ewmh.get_window_type(X11, window) end
function X11.xinerama_query_screens() return ewmh.xinerama_query_screens(X11) end
function X11.xinerama_is_active() return ewmh.xinerama_is_active(X11) end

function X11.init(desktop_count)
    X11.load_libs()
    X11.open_display(nil)
    X11.set_error_handler(function(error_code, request_code)
        debug.error("x11", "error_code=" .. tostring(error_code) .. " request_code=" .. tostring(request_code))
    end)
    X11.init_atoms()
    X11.setup_wm(desktop_count)
end

function X11.setup_wm(desktop_count)
    local width, height = X11.get_screen_size()
    local root = X11.root

    X11.store_name(root, "f3n2wm")

    local wm_check = ffi.new("uint32_t[1]", root)
    X11.change_property(root, X11.intern_atom("_NET_SUPPORTING_WM_CHECK"), X11.intern_atom("WINDOW"), 32, wm_check, 1)

    local wm_name = ffi.new("char[?]", 7)
    ffi.copy(wm_name, "f3n2wm")
    X11.change_property(root, X11.intern_atom("_NET_SUPPORTING_WM_CHECK"), X11.intern_atom("STRING"), 8, wm_name, 6)

    local pid_val = 0
    local ok, err = pcall(function() pid_val = ffi.C.getpid() end)
    if not ok then pid_val = tonumber(io.popen("echo $PPID"):read("*a")) or 0 end
    local pid = ffi.new("uint32_t[1]", pid_val)
    X11.change_property(root, X11.intern_atom("_NET_WM_PID"), X11.intern_atom("CARDINAL"), 32, pid, 1)

    local supported = {
        "_NET_SUPPORTED","_NET_CLIENT_LIST","_NET_CLIENT_LIST_STACKING",
        "_NET_NUMBER_OF_DESKTOP","_NET_DESKTOP_NAMES","_NET_ACTIVE_WINDOW",
        "_NET_WORKAREA","_NET_CURRENT_DESKTOP","_NET_WM_WINDOW_TYPE",
        "_NET_WM_STATE","_NET_WM_DESKTOP","_NET_WM_STATE_MAXIMIZED_VERT",
        "_NET_WM_STATE_MAXIMIZED_HORZ","_NET_WM_STATE_HIDDEN",
        "_NET_WM_STATE_FULLSCREEN","_NET_WM_STATE_ABOVE","_NET_WM_STATE_BELOW",
        "_NET_WM_STATE_STICKY","_NET_WM_STATE_SKIP_TASKBAR",
        "_NET_WM_STATE_SKIP_PAGER","_NET_WM_WINDOW_TYPE_DOCK",
        "_NET_WM_WINDOW_TYPE_DESKTOP","_NET_WM_WINDOW_TYPE_MENU",
        "_NET_WM_WINDOW_TYPE_SPLASH","_NET_WM_WINDOW_TYPE_DIALOG",
        "_NET_WM_WINDOW_TYPE_UTILITY","_NET_WM_WINDOW_TYPE_TOOLBAR",
        "_NET_WM_WINDOW_TYPE_NORMAL","_NET_WM_WINDOW_TYPE_NOTIFICATION",
    }
    local atoms = ffi.new("uint32_t[?]", #supported)
    for i, name in ipairs(supported) do atoms[i-1] = X11.intern_atom(name) end
    X11.change_property(root, X11.intern_atom("_NET_SUPPORTED"), X11.intern_atom("ATOM"), 32, ffi.cast("char*", atoms), #supported)

    local bg = X11.alloc_color("#000000")
    X11.libs.x11.XSetWindowBackground(X11.display, root, bg)

    local dc = ffi.new("uint32_t[1]", desktop_count or 10)
    X11.change_property(root, X11.intern_atom("_NET_NUMBER_OF_DESKTOPS"), X11.intern_atom("CARDINAL"), 32, dc, 1)

    local cd = ffi.new("uint32_t[1]", 0)
    X11.change_property(root, X11.intern_atom("_NET_CURRENT_DESKTOP"), X11.intern_atom("CARDINAL"), 32, cd, 1)

    local wa = ffi.new("uint32_t[?]", 4, 0, 0, width, height)
    X11.change_property(root, X11.intern_atom("_NET_WORKAREA"), X11.intern_atom("CARDINAL"), 32, wa, 4)

    X11.select_substructure_redirect(root)
    X11.sync()

    return { width = width, height = height }
end

return X11