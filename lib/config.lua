local bit = require("bit")
local toml = require("toml")

local config = {}

config.defaults = {
    modkey = "Mod4",
    border_width = 2,
    border_focus = "#589cc9",
    border_unfocus = "#333333",
    gap_size = 8,
    snap_pixel = 0,
    focus_follows_mouse = true,
    focus_follows_mouse_raise = false,
    mouse_follows_focus = false,
    new_window_belongs_to_master = false,
    new_window_toplevel = true,
    new_windows_on_top = true,
    click_to_focus = false,
    single_click_focus = true,
    hide_decorations = true,
    center_new_windows = false,
    resize_hints = true,
    swallow_floating = true,
    swallow_focus = true,
    smart_gaps = false,
    gapless_monocle = true,
    allow_manual_floating = true,
    float_snap_width = 100,
    float_snap_height = 100,
    float_snap_border = 20,

    layouts = {
        "master-stack",
        "spiral",
        "monocle",
        "grid",
        "tabbed",
    },

    workspaces = {
        names = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"},
        count = 10,
        scroll_layouts = true,
        scroll_fallback = false,
    },

    ipc = {
        enabled = true,
        socket_path = "/tmp/f3n2wm-ipc.sock",
    },

    keybindings = {
        ["Mod4_Return"] = "spawn:alacritty",
        ["Mod4_d"] = "spawn:rofi -show drun",
        ["Mod4_p"] = "spawn:firefox",
        ["Mod4_space"] = "layout:next",
        ["Mod4_h"] = "focus:left",
        ["Mod4_l"] = "focus:right",
        ["Mod4_k"] = "focus:up",
        ["Mod4_j"] = "focus:down",
        ["Mod4_H"] = "resize:left",
        ["Mod4_L"] = "resize:right",
        ["Mod4_K"] = "resize:up",
        ["Mod4_J"] = "resize:down",
        ["Mod4_Shift_h"] = "move:left",
        ["Mod4_Shift_l"] = "move:right",
        ["Mod4_Shift_k"] = "move:up",
        ["Mod4_Shift_j"] = "move:down",
        ["Mod4_Shift_q"] = "window:close",
        ["Mod4_m"] = "window:maximize",
        ["Mod4_f"] = "window:fullscreen",
        ["Mod4_t"] = "window:toggle_floating",
        ["Mod4_1"] = "workspace:1",
        ["Mod4_2"] = "workspace:2",
        ["Mod4_3"] = "workspace:3",
        ["Mod4_4"] = "workspace:4",
        ["Mod4_5"] = "workspace:5",
        ["Mod4_6"] = "workspace:6",
        ["Mod4_7"] = "workspace:7",
        ["Mod4_8"] = "workspace:8",
        ["Mod4_9"] = "workspace:9",
        ["Mod4_0"] = "workspace:10",
        ["Mod4_Shift_1"] = "window:move_to_workspace:1",
        ["Mod4_Shift_2"] = "window:move_to_workspace:2",
        ["Mod4_Shift_3"] = "window:move_to_workspace:3",
        ["Mod4_Shift_4"] = "window:move_to_workspace:4",
        ["Mod4_Shift_5"] = "window:move_to_workspace:5",
        ["Mod4_Shift_6"] = "window:move_to_workspace:6",
        ["Mod4_Shift_7"] = "window:move_to_workspace:7",
        ["Mod4_Shift_8"] = "window:move_to_workspace:8",
        ["Mod4_Shift_9"] = "window:move_to_workspace:9",
        ["Mod4_Shift_0"] = "window:move_to_workspace:10",
        ["Mod4_Left"] = "workspace:prev",
        ["Mod4_Right"] = "workspace:next",
        ["Mod4_Up"] = "layout:prev",
        ["Mod4_Down"] = "layout:next",
        ["Mod4_r"] = "layout:resize",
        ["Mod4_g"] = "layout:shuffle",
        ["Mod4_n"] = "layout:swap_master",
        ["Mod4_i"] = "layout:info",
        ["Mod4_e"] = "layout:toggle_split",
        ["Mod4_equal"] = "layout:incmaster",
        ["Mod4_minus"] = "layout:decmaster",
        ["Mod4_period"] = "layout:incmargin",
        ["Mod4_comma"] = "layout:decmargin",
        ["Mod4_q"] = "window:close",
        ["Mod4_w"] = "window:kill",
        ["Mod4_a"] = "workspace:toggle",
        ["Mod4_x"] = "window:maximize:horizontal",
        ["Mod4_y"] = "window:maximize:vertical",
        ["Mod4_z"] = "window:minimize",
        ["Mod4_u"] = "focus:urgent",
        ["Mod4_b"] = "bar:toggle",
        ["Mod4_v"] = "bar:reload",
        ["Mod4_F1"] = "reload",
        ["Mod4_F2"] = "restart",
        ["Mod4_F3"] = "exit",
        ["Mod4_F4"] = "layout:fullscreen",
        ["Mod4_F5"] = "layout:floating",
        ["Mod4_F6"] = "layout:toggle",
        ["Mod4_F7"] = "window:always_on_top",
        ["Mod4_F8"] = "window:sticky",
        ["Mod4_F9"] = "window:skip_taskbar",
        ["Mod4_F10"] = "window:skip_pager",
        ["Mod4_F11"] = "window:fullscreen",
        ["Mod4_F12"] = "window:maximize",
    },

    mousebinds = {
        ["Mod4_Button1"] = "move",
        ["Mod4_Button2"] = "resize",
        ["Mod4_Button3"] = "resize",
        ["Mod4_Shift_Button1"] = "move_to_workspace",
    },

    colors = {
        background = "#000000",
        foreground = "#ffffff",
        border_focus = "#589cc9",
        border_unfocus = "#333333",
        border_active = "#589cc9",
        border_normal = "#333333",
        border_urgent = "#ff0000",
        border_warning = "#e69138",
    },

    fonts = {
        main = "monospace:size=10",
        fallback = "noto-fonts:size=10",
    },

    rules = {
        { match = "Firefox", float = false, workspace = 2 },
        { match = "Gimp", float = true, workspace = 3 },
        { match = "Steam", float = false, workspace = 4 },
        { match = "Alacritty", float = false, workspace = 1 },
        { match = "Spotify", float = false, workspace = 10 },
        { match = "discord", float = false, workspace = 10 },
    },

    exec = {
        "feh --bg-scale ~/wallpaper.jpg",
        "xfce4-power-manager",
        "nm-applet",
        "pasystray",
        "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
    },

    layout_options = {
        master_count = 1,
        master_ratio = 0.5,
        column_count = 2,
        row_count = 2,
        spiral_ratio = 1.61803398875,
        tabbed_autohide = true,
        tabbed_indicator = "none",
        grid_autofill = true,
        grid_keep_aspect = false,
    },

    appearance = {
        titlebars = false,
        borders = true,
        gaps = true,
        smart_borders = true,
        roundness = 0,
        opacity = {
            focused = 1.0,
            unfocused = 0.95,
            fullscreen = 1.0,
        },
    },

    niri = {
        scroll_workspaces = true,
        scroll_factor = 1,
        scroll_animate = true,
        scroll_animation_time = 250,
        wrap_workspaces = false,
        infinite_workspaces = true,
        workspace_scroll_snap = true,
        output_scroll = true,
    },

    startup = {
        spawn_cursor = true,
        spawn_cursor_name = "left_ptr",
        set_root_color = true,
        root_color = "#000000",
        set_root_pixmap = false,
        load_fonts = true,
        init_xkb = true,
        init_xinput = true,
    },

    workspace_behavior = {
        scroll_workspaces = true,
        scroll_factor = 1,
        scroll_animate = true,
        scroll_animation_time = 250,
        wrap_workspaces = false,
        infinite_workspaces = true,
        workspace_scroll_snap = true,
        output_scroll = true,
    },

    debugging = {
        log_level = "info",
        log_file = "~/.cache/f3n2wm.log",
        log_to_stdout = true,
        log_events = false,
        log_x11 = false,
        log_layouts = true,
        log_commands = false,
        log_ipc = false,
        log_hooks = false,
        log_performance = false,
    },

    security = {
        allow_restricted_commands = false,
        ipc_acl = {},
        sandbox = true,
        restrict_env = true,
    },
}

config.key_names = {
    ["Mod1"] = 0x0008,
    ["Mod2"] = 0x0010,
    ["Mod3"] = 0x0020,
    ["Mod4"] = 0x0040,
    ["Mod5"] = 0x0080,
    ["Shift"] = 0x0001,
    ["Lock"] = 0x0002,
    ["Control"] = 0x0004,
    ["Alt"] = 0x0008,
    ["Ctrl"] = 0x0004,
    ["Super"] = 0x0040,
    ["Hyper"] = 0x0020,
    ["M"] = 0x0040,
    ["S"] = 0x0001,
    ["C"] = 0x0004,
    ["A"] = 0x0008,
}

config.keysyms = {
    Return = 0xff0d,
    space = 0x0020,
    Escape = 0xff1b,
    Tab = 0xff09,
    BackSpace = 0xff08,
    Delete = 0xffff,
    Insert = 0xff63,
    Home = 0xff50,
    Page_Up = 0xff55,
    Page_Down = 0xff56,
    End = 0xff57,
    Left = 0xff51,
    Up = 0xff52,
    Right = 0xff53,
    Down = 0xff54,
    F1 = 0xffbe, F2 = 0xffbf, F3 = 0xffc0, F4 = 0xffc1,
    F5 = 0xffc2, F6 = 0xffc3, F7 = 0xffc4, F8 = 0xffc5,
    F9 = 0xffc6, F10 = 0xffc7, F11 = 0xffc8, F12 = 0xffc9,
    equal = 0x003d, minus = 0x002d, period = 0x002e, comma = 0x002c,
}

function config.deep_copy(t)
    if type(t) ~= "table" then return t end
    local result = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            result[k] = config.deep_copy(v)
        else
            result[k] = v
        end
    end
    return result
end

function config.merge_tables(default, override)
    if type(default) ~= "table" or type(override) ~= "table" then
        return override
    end
    local result = config.deep_copy(default)
    for k, v in pairs(override) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = config.merge_tables(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

function config.load(path)
    local user_config, err = toml.load(path)
    if not user_config then
        local msg = "Config file not found or invalid: " .. path
        if err then msg = msg .. " (" .. err .. ")" end
        return nil, msg
    end

    local merged = config.merge_tables(config.defaults, user_config)
    merged._path = path
    merged._user_config = user_config
    return merged
end

function config.get_modifier_mask(modkey)
    local result = 0
    local parts = {}
    for part in modkey:gmatch("[^_]+") do
        parts[#parts+1] = part
    end

    for i = 1, #parts do
        local mod = parts[i]
        if config.key_names[mod] then
            result = bit.bor(result, config.key_names[mod])
        end
    end

    return result
end

function config.parse_keybinding(keybinding)
    local parts = {}
    for part in keybinding:gmatch("[^_]+") do
        parts[#parts+1] = part
    end

    local key = parts[#parts]
    local modifiers = {}
    for i = 1, #parts - 1 do
        modifiers[#modifiers+1] = parts[i]
    end

    local mod_mask = 0
    for _, mod in ipairs(modifiers) do
        if config.key_names[mod] then
            mod_mask = bit.bor(mod_mask, config.key_names[mod])
        end
    end

    local keysym = config.keysyms[key]
    if not keysym then
        keysym = string.byte(key:sub(1, 1))
    end

    return {
        modifiers = mod_mask,
        keysym = keysym,
        modifier_names = modifiers,
        key_name = key,
        raw = keybinding,
    }
end

function config.parse_mousebind(mousebind)
    local parts = {}
    for part in mousebind:gmatch("[^_]+") do
        parts[#parts+1] = part
    end

    local button_str = parts[#parts]
    local modifiers = {}
    for i = 1, #parts - 1 do
        modifiers[#modifiers+1] = parts[i]
    end

    local mod_mask = 0
    for _, mod in ipairs(modifiers) do
        if config.key_names[mod] then
            mod_mask = bit.bor(mod_mask, config.key_names[mod])
        end
    end

    local button_num = tonumber(button_str:match("Button(%d+)"))

    return {
        modifiers = mod_mask,
        button = button_num,
        modifier_names = modifiers,
        button_name = button_str,
        raw = mousebind,
    }
end

function config.parse_rule(rule)
    if type(rule) == "table" then
        return rule
    end
    if type(rule) == "string" then
        local parts = {}
        for part in rule:gmatch("([^;]+)") do
            parts[#parts+1] = part
        end
        local result = {}
        for _, part in ipairs(parts) do
            local key, value = part:match("^%s*(%w+)%s*:%s*(.-)%s*$")
            if key and value then
                if value == "true" then
                    result[key] = true
                elseif value == "false" then
                    result[key] = false
                else
                    local num = tonumber(value)
                    result[key] = num or value
                end
            end
        end
        return result
    end
    return nil
end

function config.expand_path(path)
    local expanded = path:gsub("~", os.getenv("HOME") or "")
    return expanded
end

function config.get_command_target(action)
    local parts = {}
    for part in action:gmatch("([^:]+)") do
        parts[#parts+1] = part
    end

    if #parts >= 2 then
        local params = {}
        for i = 3, #parts do params[i-2] = parts[i] end
        return {
            category = parts[1],
            command = parts[2],
            params = params,
        }
    end

    return nil
end

return config
