local ffi = require("ffi")

ffi.cdef[[
typedef long KeySym;
typedef unsigned long Window;
typedef unsigned long Atom;
typedef unsigned long Time;
typedef unsigned long Cursor;
typedef unsigned long Colormap;
typedef unsigned long Drawable;
typedef unsigned long VisualID;

int getpid(void);
int syscall(int number, ...);

typedef struct {
    int type;
    unsigned long serial;
    int send_event;
    void *display;
    Window window;
} XAnyEvent;

typedef struct {
    int type;
    unsigned long serial;
    int send_event;
    void *display;
    Window window;
    Window root;
    Window subwindow;
    Time time;
    int x, y;
    int x_root, y_root;
    unsigned int state;
    unsigned int keycode;
    int same_screen;
} XKeyEvent;

typedef struct {
    int type;
    unsigned long serial;
    int send_event;
    void *display;
    Window window;
    Window root;
    Window subwindow;
    Time time;
    int x, y;
    int x_root, y_root;
    unsigned int state;
    unsigned int button;
    int same_screen;
} XButtonEvent;

typedef struct {
    int type;
    unsigned long serial;
    int send_event;
    void *display;
    Window window;
    Window root;
    Window subwindow;
    Time time;
    int x, y;
    int x_root, y_root;
    unsigned int state;
    int is_hint;
    int is_xungranted;
    int same_screen;
} XMotionEvent;

typedef struct {
    int type;
    unsigned long serial;
    int send_event;
    void *display;
    Window window;
    Window root;
    Window parent;
    Window window_role;
    int x, y;
    int x_insert, y_insert;
} XMapRequestEvent;

typedef struct {
    int type;
    unsigned long serial;
    int send_event;
    void *display;
    Window window;
    Window root;
    Window subwindow;
    Time time;
    int x, y;
    int width, height;
    int border_width;
    int override_redirect;
    int win_gravity;
} XConfigureNotifyEvent;

typedef struct {
    int type;
    unsigned long serial;
    int send_event;
    void *display;
    Window window;
    Window parent;
    Window above_sibling;
    int x, y;
    int width, height;
    int border_width;
    unsigned long value_mask;
    int detail;
} XConfigureRequestEvent;

typedef struct {
    int type;
    unsigned long serial;
    int send_event;
    void *display;
    Window window;
    int x, y;
    int width, height;
    int border_width;
    Window above;
    int override_redirect;
} XGravityEvent;

typedef struct {
    int type;
    unsigned long serial;
    int send_event;
    void *display;
    Window window;
} XUnmapEvent;

typedef struct {
    int type;
    unsigned long serial;
    int send_event;
    void *display;
    Window window;
} XMapEvent;

typedef struct {
    int type;
    unsigned long serial;
    int send_event;
    void *display;
    Window window;
    Time time;
    int atom;
    int detail;
} XPropertyEvent;

typedef struct {
    int type;
    unsigned long serial;
    int send_event;
    void *display;
    Window window;
} XVisibilityEvent;

typedef union {
    long l[5];
    unsigned short s[10];
    unsigned char b[20];
} XClientMessageData;

typedef struct {
    int type;
    unsigned long serial;
    int send_event;
    void *display;
    Window window;
    Atom message_type;
    int format;
    XClientMessageData data;
} XClientMessageEvent;

typedef struct {
    int type;
    unsigned long serial;
    int send_event;
    void *display;
    Window window;
    Time time;
    int is_submap;
} XMappingEvent;

typedef union _XEvent {
    int type;
    XAnyEvent xany;
    XKeyEvent xkey;
    XButtonEvent xbutton;
    XMotionEvent xmotion;
    XConfigureRequestEvent xconfigurerequest;
    XConfigureNotifyEvent xconfigure;
    XGravityEvent xgravity;
    XUnmapEvent xunmap;
    XMapEvent xmap;
    XMapRequestEvent xmaprequest;
    XClientMessageEvent xclient;
    XPropertyEvent xproperty;
    XVisibilityEvent xvisibility;
    XMappingEvent xmapping;
} XEvent;

typedef struct {
    long flags;
    int x, y;
    int width, height;
    int min_width, min_height;
    int max_width, max_height;
    int width_inc, height_inc;
    int min_aspect_x, min_aspect_y;
    int max_aspect_x, max_aspect_y;
    int base_width, base_height;
    int win_gravity;
} XSizeHints;

typedef struct {
    long flags;
    unsigned long pixel;
    unsigned short red, green, blue;
} XColor;

typedef struct {
    long flags;
    unsigned long pixel;
    int x, y, width, height, border_width;
    int override_redirect;
    long visual;
} XSetWindowAttributes;

typedef struct {
    long flags;
    unsigned long event;
    unsigned long window;
    long x, y, width, height, border, above;
    int override_redirect;
} XWindowChanges;

typedef struct {
    char *res_name;
    char *res_class;
} XClassHint;

typedef struct {
    int screen;
    unsigned long pixel;
    int depth;
    int class;
    long visual;
    long root;
    int x, y, width, height;
    int border_width;
    int override_redirect;
    int map_state;
} XWindowAttributes;

typedef struct {
    long length;
    char *value;
} XTextProperty;

typedef struct {
    long flags;
    long event_window;
    Window window;
    int input;
    unsigned long indicator;
} XWMHints;

typedef struct {
    VisualID visualid;
    int class;
    long red_mask;
    long green_mask;
    long blue_mask;
    int bits_per_rgb;
    int map_entries;
} XVisualInfo;

typedef struct {
    int type;
    unsigned long serial;
    int send_event;
    void *display;
    int error_code;
    unsigned char request_code;
    unsigned char minor_code;
} XErrorEvent;

typedef struct {
    int max_keypermod;
    int *modifiermap;
} XModifierKeymap;

typedef struct {
    short height;
    short x;
    short y;
    short width;
    int screen_number;
    int x_org;
    int y_org;
    short width_mm;
    short height_mm;
} XineramaScreenInfo;

Display *XOpenDisplay(const char *display);
int XCloseDisplay(Display *display);
int XDefaultScreen(Display *display);
Window XDefaultRootWindow(Display *display);
int XDisplayWidth(Display *display, int screen);
int XDisplayHeight(Display *display, int screen);
int XDisplayWidthMM(Display *display, int screen);
int XDisplayHeightMM(Display *display, int screen);
unsigned long XBlackPixel(Display *display, int screen);
unsigned long XWhitePixel(Display *display, int screen);
int XSync(Display *display, int discard);
int XFlush(Display *display);
int XPending(Display *display);
int XNextEvent(Display *display, XEvent *event);
int XCheckTypedEvent(Display *display, int event_type, XEvent *event);
Atom XInternAtom(Display *display, const char *name, int only_if_exists);
char *XGetAtomName(Display *display, Atom atom);
int XChangeProperty(Display *display, Window w, Atom property, Atom type, int format, int mode, const unsigned char *data, int nelements);
int XGetWindowProperty(Display *display, Window w, Atom property, long long_offset, long long_length, int delete, Atom req_type, Atom *actual_type_return, int *actual_format_return, unsigned long *nitems_return, unsigned long *bytes_after_return, unsigned char **props_return);
int XSetInputFocus(Display *display, Window focus, int revert_to, Time time);
int XGetInputFocus(Display *display, Window *focus_return, int *revert_to_return);
int XMapWindow(Display *display, Window w);
int XUnmapWindow(Display *display, Window w);
int XRaiseWindow(Display *display, Window w);
int XLowerWindow(Display *display, Window w);
int XDestroyWindow(Display *display, Window w);
int XMoveWindow(Display *display, Window w, int x, int y);
int XResizeWindow(Display *display, Window w, unsigned int width, unsigned int height);
int XConfigureWindow(Display *display, Window w, unsigned int mask, XWindowChanges *changes);
int XSetWindowBorder(Display *display, Window w, unsigned long pixel);
int XSetWindowBorderWidth(Display *display, Window w, unsigned int width);
int XSetWindowBackground(Display *display, Window w, unsigned long pixel);
int XSelectInput(Display *display, Window w, long event_mask);
KeySym XKeysymToKeycode(Display *display, KeySym keysym);
int XUngrabKey(Display *display, KeySym keysym, unsigned int modifiers, Window w);
int XGrabKey(Display *display, int keycode, unsigned int modifiers, Window w, Window focus, int pointer_mode, int keyboard_mode);
int XGrabButton(Display *display, unsigned int button, unsigned int modifiers, Window w, int owner_events, unsigned int event_mask, unsigned int pointer_mode, unsigned int keyboard_mode);
int XUngrabButton(Display *display, unsigned int button, unsigned int modifiers, Window w);
int XSendEvent(Display *display, Window w, int propagate, unsigned long event_mask, XEvent *event_send);
Colormap XDefaultColormap(Display *display, int screen);
int XAllocColor(Display *display, Colormap colormap, XColor *color);
int XLookupColor(Display *display, Colormap colormap, const char *color_name, XColor *exact_def_return, XColor *screen_def_return);
int XFree(void *data);
Status XGetWMName(Display *display, Window w, XTextProperty *text_prop_return);
int XStringListToTextProperty(char **argv, int argc, XTextProperty *text_prop_return);
XClassHint *XAllocClassHint(void);
Status XGetClassHint(Display *display, Window w, XClassHint *class_hint_return);
void XFreeStringList(char **list);
XSizeHints *XAllocSizeHints(void);
Status XGetWMNormalHints(Display *display, Window w, XSizeHints *size_hints_return, long *wm_normal_hints_return);
XWMHints *XAllocWMHints(void);
Status XGetWMHints(Display *display, Window w, XWMHints *wm_hints_return);
int XSetWMHints(Display *display, Window w, XWMHints *wmh);
int XSetWMProtocols(Display *display, Window w, Atom *protocols, int count);
int XStoreName(Display *display, Window w, const char *name);
Cursor XCreateFontCursor(Display *display, int shape);
int XDefineCursor(Display *display, Window w, Cursor cursor);
int XUndefineCursor(Display *display, Window w);
int XWarpPointer(Display *display, Window src_window, Window dest_window, int src_x, int src_y, unsigned int src_width, unsigned int src_height, int dest_x, int dest_y);
int XQueryPointer(Display *display, Window w, Window *root_return, Window *child_return, int *x_return, int *y_return, int *win_x_return, int *win_y_return, unsigned int *mask_return);
int XGrabPointer(Display *display, Window w, int owner_events, unsigned int event_mask, unsigned int pointer_mode, unsigned int keyboard_mode, Window confine_to, Cursor cursor, Time time);
int XUngrabPointer(Display *display, Time time);
int XGrabServer(Display *display);
int XUngrabServer(Display *display);
int XAllowEvents(Display *display, int mode, Time time);
int XDeleteProperty(Display *display, Window w, Atom property);
int XQueryTree(Display *display, Window w, Window *root_return, Window *parent_return, Window **children_return, unsigned int *nchildren_return);
Status XGetWindowAttributes(Display *display, Window w, XWindowAttributes *attr_return);
Status XGetGeometry(Display *display, Drawable d, Window *root_return, int *x_return, int *y_return, unsigned int *width_return, unsigned int *height_return, unsigned int *border_width_return, unsigned int *depth_return);
long XKeycodeToKeysym(Display *display, unsigned int keycode, int index);
XModifierKeymap *XGetModifierMapping(Display *display);
int XFreeModifiermap(XModifierKeymap *modmap);
int XSetWMName(Display *display, Window w, XTextProperty *text_prop);
Window XGetSelectionOwner(Display *display, Atom selection);
int XSetSelectionOwner(Display *display, Atom selection, Window owner, Time time);
int XRefreshKeyboardMapping(void *event);
]]

local X11 = {
    libs = {},
    atoms = {},
    display = nil,
    root = nil,
    screen_number = 0,
}

function X11.load_libs()
    local ok, err
    ok, err = pcall(function()
        X11.libs.x11 = ffi.load("X11")
    end)
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

function X11.change_property(window, atom, type, format, data, nelements)
    if type(data) == "cdata" then
        X11.libs.x11.XChangeProperty(X11.display, window, atom, type, format, 1, data, nelements)
    else
        local buf = ffi.new("unsigned char[?]", #data)
        ffi.copy(buf, data, #data)
        X11.libs.x11.XChangeProperty(X11.display, window, atom, type, format, 1, buf, nelements)
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

function X11.get_wm_protocols(window)
    local prop = X11.get_property(window, X11.intern_atom("WM_PROTOCOLS"),
        X11.intern_atom("ATOM"), 1000000)
    if not prop or prop.format ~= 32 then return {} end
    local arr = ffi.cast("uint32_t*", prop.data)
    local protocols = {}
    for i = 0, prop.nitems - 1 do
        protocols[i+1] = tonumber(arr[i])
    end
    X11.libs.x11.XFree(prop.data)
    return protocols
end

function X11.send_client_message(window, message_type, data1, data2, data3, data4, data5)
    local msg = ffi.new("XClientMessageEvent")
    msg.type = 33
    msg.window = window
    msg.message_type = message_type
    msg.format = 32
    msg.data.l[0] = data1 or 0
    msg.data.l[1] = data2 or 0
    msg.data.l[2] = data3 or 0
    msg.data.l[3] = data4 or 0
    msg.data.l[4] = data5 or 0
    local event = ffi.new("XEvent")
    ffi.copy(event, msg, ffi.sizeof("XClientMessageEvent"))
    X11.libs.x11.XSendEvent(X11.display, X11.root, 0, 0x00020000, ffi.cast("XEvent*", event))
end

function X11.get_window_attributes(window)
    local attrs = ffi.new("XWindowAttributes")
    local result = X11.libs.x11.XGetWindowAttributes(X11.display, window, attrs)
    if result == 0 then return nil end
    return { x = tonumber(attrs.x), y = tonumber(attrs.y),
             width = tonumber(attrs.width), height = tonumber(attrs.height),
             border_width = tonumber(attrs.border_width),
             override_redirect = tonumber(attrs.override_redirect) }
end

function X11.get_window_geometry(window)
    local root = ffi.new("Window[1]")
    local child = ffi.new("Window[1]")
    local x = ffi.new("int[1]"); local y = ffi.new("int[1]")
    local w = ffi.new("unsigned int[1]"); local h = ffi.new("unsigned int[1]")
    local b = ffi.new("unsigned int[1]"); local d = ffi.new("unsigned int[1]")
    local result = X11.libs.x11.XGetGeometry(X11.display, window, root, x, y, w, h, b, d)
    if result == 0 then return nil end
    return { x = tonumber(x[0]), y = tonumber(y[0]),
             width = tonumber(w[0]), height = tonumber(h[0]) }
end

function X11.move_window(window, x, y)
    X11.libs.x11.XMoveWindow(X11.display, window, x, y)
end

function X11.resize_window(window, width, height)
    X11.libs.x11.XResizeWindow(X11.display, window, width, height)
end

function X11.move_resize_window(window, x, y, width, height)
    local changes = ffi.new("XWindowChanges")
    changes.x = x; changes.y = y
    changes.width = width; changes.height = height
    changes.border_width = 0
    local mask = 0x0001 | 0x0002 | 0x0004 | 0x0008
    X11.libs.x11.XConfigureWindow(X11.display, window, mask, changes)
end

function X11.set_window_border(window, pixel)
    X11.libs.x11.XSetWindowBorder(X11.display, window, pixel)
end

function X11.set_window_border_width(window, width)
    X11.libs.x11.XSetWindowBorderWidth(X11.display, window, width)
end

function X11.map_window(window)
    X11.libs.x11.XMapWindow(X11.display, window)
end

function X11.unmap_window(window)
    X11.libs.x11.XUnmapWindow(X11.display, window)
end

function X11.raise_window(window)
    X11.libs.x11.XRaiseWindow(X11.display, window)
end

function X11.lower_window(window)
    X11.libs.x11.XLowerWindow(X11.display, window)
end

function X11.destroy_window(window)
    X11.libs.x11.XDestroyWindow(X11.display, window)
end

function X11.select_input(window, event_mask)
    X11.libs.x11.XSelectInput(X11.display, window, event_mask)
end

function X11.grab_key(window, keycode, modifiers)
    X11.libs.x11.XGrabKey(X11.display, keycode, modifiers, window, 0, 1, 0)
end

function X11.grab_button(window, button, modifiers)
    X11.libs.x11.XGrabButton(X11.display, button, modifiers, window, 0,
        0x0001 | 0x0002 | 0x0004 | 0x0008, 0x0001 | 0x0002 | 0x0004, 0, 0)
end

function X11.set_input_focus(window)
    X11.libs.x11.XSetInputFocus(X11.display, window, 0, 0)
end

function X11.get_input_focus()
    local focus = ffi.new("Window[1]")
    local revert = ffi.new("int[1]")
    X11.libs.x11.XGetInputFocus(X11.display, focus, revert)
    return tonumber(focus[0])
end

function X11.sync()
    X11.libs.x11.XSync(X11.display, 0)
end

function X11.flush()
    X11.libs.x11.XFlush(X11.display)
end

function X11.pending_events()
    return X11.libs.x11.XPending(X11.display)
end

function X11.next_event(event)
    return X11.libs.x11.XNextEvent(X11.display, event)
end

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

function X11.delete_property(window, atom)
    X11.libs.x11.XDeleteProperty(X11.display, window, atom)
end

function X11.parse_hex_color(hex)
    local r, g, b = hex:match("#(%x%x)(%x%x)(%x%x)")
    if not r then r, g, b = "00", "00", "00" end
    return tonumber(r, 16) / 255 * 65535,
           tonumber(g, 16) / 255 * 65535,
           tonumber(b, 16) / 255 * 65535
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

function X11.add_wm_state(window, state_atom)
    local msg = ffi.new("XClientMessageEvent")
    msg.type = 33; msg.window = window
    msg.message_type = X11.intern_atom("_NET_WM_STATE")
    msg.format = 32; msg.data.l[0] = 1; msg.data.l[1] = state_atom
    local event = ffi.new("XEvent")
    ffi.copy(event, msg, ffi.sizeof("XClientMessageEvent"))
    X11.libs.x11.XSendEvent(X11.display, X11.root, 0, 0x00020000, ffi.cast("XEvent*", event))
end

function X11.remove_wm_state(window, state_atom)
    local msg = ffi.new("XClientMessageEvent")
    msg.type = 33; msg.window = window
    msg.message_type = X11.intern_atom("_NET_WM_STATE")
    msg.format = 32; msg.data.l[0] = 0; msg.data.l[1] = state_atom
    local event = ffi.new("XEvent")
    ffi.copy(event, msg, ffi.sizeof("XClientMessageEvent"))
    X11.libs.x11.XSendEvent(X11.display, X11.root, 0, 0x00020000, ffi.cast("XEvent*", event))
end

function X11.toggle_wm_state(window, state_atom)
    local msg = ffi.new("XClientMessageEvent")
    msg.type = 33; msg.window = window
    msg.message_type = X11.intern_atom("_NET_WM_STATE")
    msg.format = 32; msg.data.l[0] = 2; msg.data.l[1] = state_atom
    local event = ffi.new("XEvent")
    ffi.copy(event, msg, ffi.sizeof("XClientMessageEvent"))
    X11.libs.x11.XSendEvent(X11.display, X11.root, 0, 0x00020000, ffi.cast("XEvent*", event))
end

function X11.get_wm_state_atoms(window)
    local prop = X11.get_property(window, X11.intern_atom("_NET_WM_STATE"),
        X11.intern_atom("ATOM"), 1000000)
    if not prop or prop.format ~= 32 then return {} end
    local arr = ffi.cast("uint32_t*", prop.data)
    local state = {}
    for i = 0, prop.nitems - 1 do state[i+1] = tonumber(arr[i]) end
    X11.libs.x11.XFree(prop.data)
    return state
end

function X11.get_window_type(window)
    local prop = X11.get_property(window, X11.intern_atom("_NET_WM_WINDOW_TYPE"),
        X11.intern_atom("ATOM"), 1000000)
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

function X11.get_class_hint(window)
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

function X11.get_normal_hints(window)
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

function X11.get_wm_hints(window)
    local p = X11.libs.x11.XAllocWMHints()
    local hints = ffi.cast("XWMHints*", p)
    local result = X11.libs.x11.XGetWMHints(X11.display, window, hints)
    if result == 0 then X11.libs.x11.XFree(p) return nil end
    local h = { flags = tonumber(hints.flags), input = tonumber(hints.input) }
    X11.libs.x11.XFree(p)
    return h
end

function X11.get_active_window()
    local prop = X11.get_property(X11.root, X11.intern_atom("_NET_ACTIVE_WINDOW"),
        X11.intern_atom("WINDOW"), 1)
    if not prop or prop.format ~= 32 then return nil end
    local val = ffi.cast("uint32_t*", prop.data)[0]
    X11.libs.x11.XFree(prop.data)
    return tonumber(val)
end

function X11.set_active_window(window)
    X11.libs.x11.XSetInputFocus(X11.display, window, 0, 0)
end

function X11.get_current_desktop()
    local prop = X11.get_property(X11.root, X11.intern_atom("_NET_CURRENT_DESKTOP"),
        X11.intern_atom("CARDINAL"), 1)
    if not prop or prop.format ~= 32 then return 0 end
    local val = ffi.cast("uint32_t*", prop.data)[0]
    X11.libs.x11.XFree(prop.data)
    return tonumber(val)
end

function X11.set_current_desktop(desktop)
    local data = ffi.new("uint32_t[1]", desktop)
    X11.change_property(X11.root, X11.intern_atom("_NET_CURRENT_DESKTOP"),
        X11.intern_atom("CARDINAL"), 32, data, 1)
end

function X11.get_desktop_names()
    local prop = X11.get_property(X11.root, X11.intern_atom("_NET_DESKTOP_NAMES"),
        X11.intern_atom("STRING"), 1000000)
    if not prop or prop.format ~= 8 then return {} end
    local str = ffi.string(prop.data, prop.nitems)
    X11.libs.x11.XFree(prop.data)
    local names = {}
    for name in str:gmatch("([^%z]+)") do names[#names+1] = name end
    return names
end

function X11.set_desktop_names(names)
    local str = table.concat(names, "\0") .. "\0"
    local data = ffi.new("char[?]", #str)
    ffi.copy(data, str)
    X11.change_property(X11.root, X11.intern_atom("_NET_DESKTOP_NAMES"),
        X11.intern_atom("STRING"), 8, data, #str)
end

function X11.set_client_list(windows)
    if #windows == 0 then return end
    local arr = ffi.new("uint32_t[?]", #windows)
    for i, w in ipairs(windows) do arr[i-1] = w end
    X11.change_property(X11.root, X11.intern_atom("_NET_CLIENT_LIST"),
        X11.intern_atom("WINDOW"), 32, ffi.cast("char*", arr), #windows)
end

function X11.set_client_list_stacking(windows)
    if #windows == 0 then return end
    local arr = ffi.new("uint32_t[?]", #windows)
    for i, w in ipairs(windows) do arr[i-1] = w end
    X11.change_property(X11.root, X11.intern_atom("_NET_CLIENT_LIST_STACKING"),
        X11.intern_atom("WINDOW"), 32, ffi.cast("char*", arr), #windows)
end

function X11.set_workarea(rects)
    local count = #rects
    local data = ffi.new("uint32_t[?]", 4 * count)
    for i, r in ipairs(rects) do
        local off = (i - 1) * 4
        data[off + 0] = r.x; data[off + 1] = r.y
        data[off + 2] = r.width; data[off + 3] = r.height
    end
    X11.change_property(X11.root, X11.intern_atom("_NET_WORKAREA"),
        X11.intern_atom("CARDINAL"), 32, data, 4 * count)
end

function X11.xinerama_query_screens()
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

function X11.xinerama_is_active()
    if not X11.libs.xinerama then return false end
    return X11.libs.xinerama.XineramaIsActive(X11.display) ~= 0
end

function X11.select_substructure_redirect(root)
    X11.libs.x11.XSelectInput(X11.display, root,
        0x00100000 | 0x00200000 | 0x00040000 |
        0x00000001 | 0x00000002 | 0x00000004 | 0x00000008 |
        0x00000010 | 0x00000020 | 0x00000040 | 0x00020000)
end

function X11.get_pointer_position()
    local rr = ffi.new("Window[1]"); local cr = ffi.new("Window[1]")
    local x = ffi.new("int[1]"); local y = ffi.new("int[1]")
    local wx = ffi.new("int[1]"); local wy = ffi.new("int[1]")
    local mask = ffi.new("unsigned int[1]")
    local result = X11.libs.x11.XQueryPointer(X11.display, X11.root,
        rr, cr, x, y, wx, wy, mask)
    return { x = tonumber(x[0]), y = tonumber(y[0]),
             mask = tonumber(mask[0]), same_screen = result ~= 0 }
end

function X11.warp_pointer(dest_x, dest_y)
    X11.libs.x11.XWarpPointer(X11.display, ffi.cast("Window", 0),
        X11.root, 0, 0, 0, 0, dest_x, dest_y)
end

function X11.grab_pointer(window)
    return X11.libs.x11.XGrabPointer(X11.display, window, 0,
        0x0001 | 0x0002 | 0x0004 | 0x0008, 0x0001 | 0x0002 | 0x0004 | 0x0008, 0, 0)
end

function X11.ungrab_pointer(time)
    X11.libs.x11.XUngrabPointer(X11.display, time or 0)
end

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

function X11.keysym_to_keycode(keysym)
    local kc = X11.libs.x11.XKeysymToKeycode(X11.display, keysym)
    return tonumber(kc)
end

function X11.keycode_to_keysym(keycode, index)
    local sym = X11.libs.x11.XKeycodeToKeysym(X11.display, keycode, index or 0)
    return tonumber(sym)
end

function X11.grab_server()
    X11.libs.x11.XGrabServer(X11.display)
end

function X11.ungrab_server()
    X11.libs.x11.XUngrabServer(X11.display)
end

function X11.allow_events(mode, time)
    X11.libs.x11.XAllowEvents(X11.display, mode, time or 0)
end

function X11.set_error_handler(callback)
    local fn = ffi.cast("int (*)(void*, void*)", function(display, error_ptr)
        local err = ffi.cast("XErrorEvent*", error_ptr)
        if callback then callback(tonumber(err.error_code), tonumber(err.request_code)) end
        return 0
    end)
    X11._error_handler = fn
    X11.libs.x11.XSetErrorHandler(fn)
end

function X11.create_font_cursor(shape)
    return X11.libs.x11.XCreateFontCursor(X11.display, shape or 0)
end

function X11.define_cursor(window, cursor)
    X11.libs.x11.XDefineCursor(X11.display, window, cursor)
end

function X11.init_atoms()
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

function X11.setup_wm()
    local width, height = X11.get_screen_size()
    local root = X11.root

    X11.store_name(root, "f3n2wm")

    local wm_check = ffi.new("uint32_t[1]", root)
    X11.change_property(root, X11.intern_atom("WM_CHECK"),
        X11.intern_atom("WINDOW"), 32, wm_check, 1)

    local wm_name = ffi.new("char[?]", 5)
    ffi.copy(wm_name, "WMWM")
    X11.change_property(root, X11.intern_atom("WM_CHECK"),
        X11.intern_atom("STRING"), 8, wm_name, 4)

    local pid_val = 0
    local ok, err = pcall(function()
        pid_val = ffi.C.getpid()
    end)
    if not ok then
        pid_val = tonumber(io.popen("echo $PPID"):read("*a")) or 0
    end
    local pid = ffi.new("uint32_t[1]", pid_val)
    X11.change_property(root, X11.intern_atom("_NET_WM_PID"),
        X11.intern_atom("CARDINAL"), 32, pid, 1)

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
    X11.change_property(root, X11.intern_atom("_NET_SUPPORTED"),
        X11.intern_atom("ATOM"), 32, ffi.cast("char*", atoms), #supported)

    local bg = X11.alloc_color("#000000")
    X11.libs.x11.XSetWindowBackground(X11.display, root, bg)

    local dc = ffi.new("uint32_t[1]", 1)
    X11.change_property(root, X11.intern_atom("_NET_NUMBER_OF_DESKTOP"),
        X11.intern_atom("CARDINAL"), 32, dc, 1)

    local cd = ffi.new("uint32_t[1]", 0)
    X11.change_property(root, X11.intern_atom("_NET_CURRENT_DESKTOP"),
        X11.intern_atom("CARDINAL"), 32, cd, 1)

    local wa = ffi.new("uint32_t[?]", 4, 0, 0, width, height)
    X11.change_property(root, X11.intern_atom("_NET_WORKAREA"),
        X11.intern_atom("CARDINAL"), 32, wa, 4)

    X11.select_substructure_redirect(root)
    X11.sync()

    return { width = width, height = height }
end

function X11.init()
    X11.load_libs()
    X11.open_display(nil)
    X11.init_atoms()
    X11.setup_wm()
end

return X11
