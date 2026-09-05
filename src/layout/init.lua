local engine = require("layout.engine")
local loader = require("layout.loader")
local debug = require("debug")

require("layout.algorithms")

local layout = {}
layout.layouts = {}
layout.order = {}
layout.by_name = {}

function layout.register(def)
    if not def or not def.name then
        debug.warn("layout", "attempted to register a layout without a name")
        return
    end
    if not layout.by_name[def.name] then
        layout.order[#layout.order+1] = def.name
    end
    layout.by_name[def.name] = def
    debug.debug("layout", "registered layout '" .. def.name .. "'")
end

function layout.load_builtin(base_path)
    local preset_dir = base_path .. "/src/config/presets"
    local presets = loader.load_dir(preset_dir)
    for _, def in ipairs(presets) do
        layout.register(def)
    end
    debug.info("layout", "loaded " .. #presets .. " builtin presets from " .. preset_dir)
end

function layout.load_user_layouts(base_path, config)
    local user_dir = config and config.layout_dir
    if not user_dir then return end
    local user_layouts = loader.load_user_layouts(user_dir)
    for _, def in ipairs(user_layouts) do
        layout.register(def)
    end
    debug.info("layout", "loaded " .. #user_layouts .. " user layouts from " .. user_dir)
end

function layout.list_layout_names()
    local names = {}
    for _, name in ipairs(layout.order) do
        names[#names+1] = name
    end
    return names
end

function layout.get_layout(name)
    return layout.by_name[name]
end

function layout.arrange(name, windows, rect, cfg)
    local def = layout.by_name[name]
    if not def then
        debug.warn("layout", "layout '" .. tostring(name) .. "' not found, skipping arrange")
        return
    end
    engine.arrange(def, windows, rect, cfg)
end

return layout