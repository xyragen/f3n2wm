local ffi = require("ffi")
local bit = require("bit")

local display = {}

display.cdef = [[
typedef int Bool;
typedef int Status;
typedef struct _XDisplay Display;
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
int XGrabKey(Display *display, int keycode, unsigned int modifiers, Window w, int owner_events, int pointer_mode, int keyboard_mode);
int XGrabButton(Display *display, unsigned int button, unsigned int modifiers, Window w, int owner_events, unsigned int event_mask, int pointer_mode, int keyboard_mode, Window confine_to, Cursor cursor);
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
int XSetErrorHandler(int (*handler)(Display *, XErrorEvent *));
int XDisplayKeycodes(Display *display, int *min_keycodes_return, int *max_keycodes_return);
]]

display.cdef_xinerama = [[
Bool XineramaQueryScreens(Display *display, int *number_return);
Bool XineramaIsActive(Display *display);
]]

return display