#!/usr/bin/env luajit

local args = {...}
local base_path = args[1] or "."

package.path = base_path .. "/src/?.lua;" .. base_path .. "/src/?/init.lua;" ..
               base_path .. "/src/?/?.lua;" .. base_path .. "/?.lua;" ..
               base_path .. "/layouts/?.lua;" .. package.path

local wm = require("wm")
local events = require("events")
local debug = require("debug")

local user_dir = os.getenv("HOME") .. "/.config/f3n2wm"
local config = require("config").load(base_path, user_dir)

debug.configure(config.debugging or {})
debug.info("wm", "starting f3n2wm from " .. base_path)

local instance = wm.new(base_path, config)
events.install(instance)

local ok, err = pcall(instance.startup, instance)
if not ok then
    debug.error("wm", "failed to start: " .. tostring(err))
    io.stderr:write("[f3n2wm] Failed to start: " .. tostring(err) .. "\n")
    os.exit(1)
end

instance:run()