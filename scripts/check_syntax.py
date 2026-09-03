#!/usr/bin/env python3
import lupa
import sys
import os

lua = lupa.LuaRuntime()

base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
base_fwd = base.replace("\\", "/")
lua.execute("package.path = '" + base_fwd + "/lib/?.lua;" + base_fwd + "/?.lua;" + base_fwd + "/layouts/?.lua;' .. package.path")

src = """
local ffi_mock = {}
ffi_mock.cdef = function() end
ffi_mock.load = function(name) return {} end
ffi_mock.cast = function(...) return nil end
ffi_mock.new = function(...) return nil end
ffi_mock.string = function(...) return "" end
ffi_mock.copy = function(...) end
ffi_mock.sizeof = function(...) return 0 end
ffi_mock.typeof = function(...) return nil end
ffi_mock.type = function(...) return "cdata" end
setmetatable(ffi_mock, {__index = function(t, k) return function(...) return nil end end})
package.preload["ffi"] = function() return ffi_mock end
"""
lua.execute(src)

load_fn = lua.eval("load")

files = [
    "init.lua",
    "lib/config.lua",
    "lib/hook.lua",
    "lib/input.lua",
    "lib/ipc.lua",
    "lib/layout.lua",
    "lib/toml.lua",
    "lib/window.lua",
    "lib/workspace.lua",
    "lib/x11.lua",
    "layouts/masterstack.lua",
    "layouts/spiral.lua",
    "layouts/monocle.lua",
    "layouts/grid.lua",
    "layouts/tabbed.lua",
]

def strip_shebang(s):
    if s.startswith("#!"):
        idx = s.find("\n")
        if idx >= 0:
            return s[idx+1:]
        return ""
    return s

all_ok = True
for f in files:
    path = os.path.join(base, f)
    try:
        with open(path, "r") as fh:
            src = fh.read()
        src = strip_shebang(src)
        result = load_fn(src)
        if result is None:
            all_ok = False
            print("FAIL: " + f + " (compilation returned nil)")
        else:
            print("OK: " + f)
    except lupa.LuaError as e:
        all_ok = False
        print("FAIL: " + f)
        print("  " + str(e))
    except Exception as e:
        all_ok = False
        print("ERROR: " + f + ": " + str(e))

sys.exit(0 if all_ok else 1)
