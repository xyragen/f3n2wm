local config_mod = require("config")
local keybindings = require("wm.keybindings")
local commands = require("wm.commands")
local lifecycle = require("wm.lifecycle")

local wm = {}
wm.__index = wm

function wm.new(base_path, config)
    local self = setmetatable({}, wm)
    self.base_path = base_path
    self.config = config or config_mod.load(base_path)
    self.config_dir = os.getenv("HOME") .. "/.config/f3n2wm"
    self.running = true
    self.screen_width = 0
    self.screen_height = 0
    self.master_count = 1
    self.master_ratio = 0.5
    self.gap_size = 8
    self.border_focus = "#589cc9"
    self.border_unfocus = "#333333"
    self.border_width = 2
    self.is_exiting = false
    self.config_reload_pending = false
    self.keybindings = {}

    keybindings.install(self)
    commands.install(self)
    lifecycle.install(self)

    return self
end

return wm