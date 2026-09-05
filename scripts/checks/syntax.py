#!/usr/bin/env python3
import lupa
import sys
import os

lua = lupa.LuaRuntime()

base = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
base_fwd = base.replace("\\", "/")
lua.execute("package.path = '" + base_fwd + "/src/?.lua;" + base_fwd + "/src/?/init.lua;" + base_fwd + "/src/?/?.lua;" + base_fwd + "/layouts/?.lua;" + base_fwd + "/?.lua;' .. package.path")

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

def collect_lua_files(root_dir):
    found = []
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for name in sorted(filenames):
            if name.endswith(".lua"):
                full = os.path.join(dirpath, name)
                rel = os.path.relpath(full, base).replace("\\", "/")
                found.append(rel)
    return sorted(found)

files = collect_lua_files(os.path.join(base, "src"))
files.append("init.lua") if os.path.exists(os.path.join(base, "init.lua")) else None

all_ok = True
for f in files:
    path = os.path.join(base, f)
    try:
        with open(path, "r") as fh:
            src = fh.read()
        if src.startswith("#!"):
            idx = src.find("\n")
            src = src[idx+1:] if idx >= 0 else ""
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