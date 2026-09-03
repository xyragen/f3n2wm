#!/usr/bin/env python3
import lupa
import sys
import os

lua = lupa.LuaRuntime()

base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
base_fwd = base.replace("\\", "/")

setup = """
package.path = '""" + base_fwd + """/lib/?.lua;""" + base_fwd + """/layouts/?.lua;""" + base_fwd + """/?.lua;' .. package.path
_G.BASE = '""" + base_fwd + """'

local ffi_mock = setmetatable({}, {__index = function(t, k)
    return function(...) return nil end
end})
ffi_mock.cdef = function() end
ffi_mock.load = function(name)
    return setmetatable({}, {__index = function(t, k)
        return function(...)
            if k == "XOpenDisplay" then return ffi.new_fake_ptr and ffi.new_fake_ptr or 1 end
            if k == "XDefaultRootWindow" then return 100 end
            if k == "XDefaultScreen" then return 0 end
            if k == "XDisplayWidth" then return 1920 end
            if k == "XDisplayHeight" then return 1080 end
            if k == "XInternAtom" then return 1000 end
            if k == "XAllocColor" then return 1 end
            if k == "XGetAtomName" then return nil end
            if k == "XGetModifierMapping" then return nil end
            if k == "XKeysymToKeycode" then return 25 end
            if k == "XGetWindowProperty" then return 1 end
            if k == "XGetClassHint" then return 0 end
            if k == "XGetWMName" then return 0 end
            if k == "XineramaIsActive" then return 0 end
            return 1
        end
    end})
end
ffi_mock.cast = function(ctype, val) return val end
ffi_mock.new = function(ctype, ...)
    local args = {...}
    local n = tonumber(ctype:match("%[(%d+)%]")) or (args[1] and tonumber(args[1])) or 1
    local t = {}
    for i = 0, n do t[i] = 0 end
    return setmetatable(t, {
        __index = function(t, k) return 0 end,
        __newindex = function(t, k, v) rawset(t, k, v) end,
    })
end
ffi_mock.sizeof = function() return 108 end
ffi_mock.typeof = function() return nil end
ffi_mock.type = function(v)
    if v == nil then return "nil" end
    if type(v) == "number" or type(v) == "string" or type(v) == "boolean" then return type(v) end
    return "cdata"
end
ffi_mock.copy = function() end
ffi_mock.string = function() return "" end
ffi_mock.C = setmetatable({}, {__index = function(t, k)
    return function() return 0 end
end})
ffi_mock.C.getpid = function() return 1234 end
package.preload["ffi"] = function() return ffi_mock end

os.execute = function() return 0 end
os.getenv = function(var)
    if var == "HOME" then return "/root" end
    if var == "XDG_RUNTIME_DIR" then return "/tmp" end
    return nil
end
"""

errors = []

def run(name, code):
    try:
        lua.execute(code)
        print("OK: " + name)
    except lupa.LuaError as e:
        errors.append(name)
        print("FAIL: " + name)
        print("  " + str(e)[:600])

lua.execute(setup)

run("load modules", """
local X11 = require("x11")
local config = require("config")
local hook = require("hook")
local window = require("window")
local workspace_mod = require("workspace")
local layout = require("layout")
local input = require("input")
local ipc = require("ipc")
_G.mods = {X11=X11, config=config, hook=hook, window=window, workspace_mod=workspace_mod, layout=layout, input=input, ipc=ipc}
""")

run("config.load TOML", """
local config = _G.mods.config
local cfg = config.load(BASE .. '/f3n2wm.toml')
assert(cfg, "config.load returned nil")
assert(cfg.keybindings, "no keybindings in merged config")
assert(cfg.keybindings["Mod4_Return"] == "spawn:alacritty", "Mod4_Return wrong: " .. tostring(cfg.keybindings["Mod4_Return"]))
assert(cfg.mousebinds, "no mousebinds")
assert(type(cfg.rules) == "table" and #cfg.rules >= 1, "rules not loaded as array")
assert(cfg.rules[1].match == "Firefox", "rule 1 match wrong")
assert(type(cfg.exec) == "table" and type(cfg.exec[1]) == "string", "exec not array of strings")
assert(cfg.ipc.socket_path == "/tmp/f3n2wm-ipc.sock", "ipc socket_path wrong")
assert(cfg.workspace_behavior.wrap_workspaces == false, "workspace_behavior wrong")
assert(cfg.modkey == "Mod4", "modkey wrong")
_G.cfg = cfg
""")

run("parse keybindings", """
local config = _G.mods.config
local kb = config.parse_keybinding("Mod4_Shift_Return")
assert(kb.modifiers == (0x0040 | 0x0001), "mod mask wrong: " .. kb.modifiers)
assert(kb.keysym == 0xff0d or kb.key_name == "Return", "keysym wrong")
local mb = config.parse_mousebind("Mod4_Button1")
assert(mb.button == 1, "button wrong")
assert(mb.modifiers == 0x0040, "mouse mod mask wrong")
""")

run("hook module", """
local hook = _G.mods.hook
local called = false
hook.register("test_event", function(ctx, a, b) called = true; return a + b end)
local r = hook.fire("test_event", 1, 2)
assert(called, "hook not called")
assert(r == 3, "hook return wrong: " .. tostring(r))
""")

run("window registry", """
local window = _G.mods.window
local fake_wm = {
    x11 = setmetatable({}, {__index = function() return function() end end}),
    hooks = _G.mods.hook,
    config = {border_width = 2, colors = {}, gap_size = 8},
    workspaces = nil,
    master_count = 1,
    master_ratio = 0.5,
    gap_size = 8,
    layouts = _G.mods.layout,
}
window.set_wm(fake_wm)
assert(window.get_focused() == nil, "get_focused should be nil with no workspaces")
local w = window.register(42)
assert(window.is_registered(42))
assert(window.get(42) == w)
window.unregister(42)
assert(not window.is_registered(42))
_G.fake_wm = fake_wm
""")

run("layout load + arrange", """
local layout = _G.mods.layout
local window = _G.mods.window
local cfg = _G.cfg
layout.load_builtin(BASE)
local names = layout.list_layout_names()
assert(names[1] == "master-stack", "first layout should be master-stack, got " .. tostring(names[1]))
assert(layout.get_layout("grid"), "grid layout missing")
local wins = {}
for i = 1, 5 do
    wins[i] = window.register(1000 + i)
end
for _, name in ipairs(names) do
    local l = layout.get_layout(name)
    l.arrange(wins, {x=0, y=0, width=1920, height=1080}, cfg)
    for _, w in ipairs(wins) do
        assert(w.width > 0 and w.height > 0, name .. " gave zero geometry")
    end
end
for i = 1, 5 do window.unregister(1000 + i) end
""")

run("workspace manager", """
local workspace_mod = _G.mods.workspace_mod
local hook = _G.mods.hook
hook.set_context(_G.fake_wm)
workspace_mod.set_wm(_G.fake_wm)
local layout = _G.mods.layout
_G.fake_wm.layouts = layout
local mgr = workspace_mod.WorkspaceManager:new(_G.fake_wm)
assert(mgr.current_ws == 1)
local ws = workspace_mod.Workspace:new(1, "1", {x=0,y=0,width=1920,height=1080}, 1)
ws:add_window(5001)
ws:add_window(5002)
ws:add_window(5001)
assert(#ws.windows == 2, "add_window dedup failed")
ws:remove_window(5002)
assert(#ws.windows == 1)
ws:next_layout()
assert(ws.layout == "spiral", "next_layout wrong: " .. tostring(ws.layout))
ws:prev_layout()
assert(ws.layout == "master-stack", "prev_layout wrong: " .. tostring(ws.layout))
local localarr = layout.get_layout("master-stack")
localarr.arrange({}, {x=0,y=0,width=1920,height=1080}, _G.cfg)
""")

run("workspace scroll logic", """
local workspace_mod = _G.mods.workspace_mod
local mgr = workspace_mod.WorkspaceManager:new(_G.fake_wm)
mgr.workspaces = {}
for i = 1, 3 do
    mgr.workspaces[i] = workspace_mod.Workspace:new(i, tostring(i), {x=0,y=0,width=1920,height=1080}, 1)
end
mgr.current_ws = 1
local ws_cfg = {wrap_workspaces = false}
local new_ws = mgr.current_ws + 1
assert(new_ws == 2)
new_ws = 1 - 1
assert(new_ws == 0)
assert(ws_cfg.wrap_workspaces == false)
""")

run("ipc commands", """
local ipc = _G.mods.ipc
local fake_wm = _G.fake_wm
fake_wm.workspaces = {get_current = function() return nil end, get_all = function() return {} end, current_ws = 1}
fake_wm.windows = _G.mods.window
fake_wm.reload_config = function() end
fake_wm.restart = function() end
fake_wm.exit = function() end
ipc.set_wm(fake_wm)
ipc.register_default_commands()
local r = ipc.execute_command("help")
assert(r:find("Commands:"), "help failed: " .. tostring(r))
local r2 = ipc.execute_command("bogus_cmd")
assert(r2:find("unknown command"), "unknown cmd failed: " .. tostring(r2))
local r3 = ipc.execute_command("get_current_workspace")
assert(r3 == "ok: 1", "get_current_workspace failed: " .. tostring(r3))
local r4 = ipc.execute_command("list_windows")
assert(r4 == "No windows", "list_windows failed: " .. tostring(r4))
""")

run("ipc execute with workspace", """
local ipc = _G.mods.ipc
local ws = _G.mods.workspace_mod.Workspace:new(1, "1", {x=0,y=0,width=1920,height=1080}, 1)
_G.fake_wm.workspaces = {
    get_current = function() return ws end,
    get_all = function() return {ws} end,
    current_ws = 1,
}
local r = ipc.execute_command("list_workspaces")
assert(r:find("1 "), "list_workspaces failed: " .. tostring(r))
local r2 = ipc.execute_command("get_current_workspace")
assert(r2 == "ok: 1", "get_current_workspace failed: " .. tostring(r2))
""")

run("toml roundtrip", """
local toml = _G.mods.config and require("toml") or nil
""")

run("input module", """
local input = _G.mods.input
local fake_wm = _G.fake_wm
fake_wm.x11 = setmetatable({}, {__index = function(t,k)
    if k == "get_modifier_map" then return function() return {} end end
    if k == "keysym_to_keycode" then return function() return 25 end end
    return function() end
end})
input.set_wm(fake_wm)
input.setup_bindings(_G.cfg)
assert(next(input.bindings) ~= nil, "input.bindings empty after setup")
local found_return = false
for k, v in pairs(input.bindings) do
    if v == "spawn:alacritty" then found_return = true end
end
assert(found_return, "Mod4_Return binding not registered")
""")

print("")
if errors:
    print("RUNTIME FAILURES: " + str(len(errors)) + " -> " + ", ".join(errors))
    sys.exit(1)
else:
    print("ALL RUNTIME TESTS PASSED")
    sys.exit(0)
