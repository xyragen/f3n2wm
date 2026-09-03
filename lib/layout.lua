local layout = {}

layout.layouts = {}
layout.order = {}
layout.default = "master-stack"

function layout.register(name, mod)
    if not layout.layouts[name] then
        layout.order[#layout.order + 1] = name
    end
    layout.layouts[name] = mod
end

function layout.get_layout(name)
    return layout.layouts[name]
end

function layout.list_layout_names()
    local names = {}
    for _, name in ipairs(layout.order) do
        names[#names+1] = name
    end
    return names
end

function layout.load_builtin(base_path)
    local layout_files = {
        {"master-stack", "layouts/masterstack.lua"},
        {"spiral", "layouts/spiral.lua"},
        {"monocle", "layouts/monocle.lua"},
        {"grid", "layouts/grid.lua"},
        {"tabbed", "layouts/tabbed.lua"},
    }
    for _, entry in ipairs(layout_files) do
        local name, path = entry[1], entry[2]
        local full_path = base_path .. "/" .. path
        local ok, mod = pcall(dofile, full_path)
        if ok and mod and mod.arrange then
            layout.register(name, mod)
        else
            local ok2, mod2 = pcall(require, name)
            if ok2 and mod2 and mod2.arrange then
                layout.register(name, mod2)
            end
        end
    end
end

function layout.load_user_layouts(base_path, config)
    if not config.layouts or not config.layouts.user then return end
    for _, path in ipairs(config.layouts.user) do
        local full_path = base_path .. "/" .. path
        local ok, mod = pcall(dofile, full_path)
        if ok and mod and mod.name and mod.arrange then
            layout.register(mod.name, mod)
        end
    end
end

function layout.get_master_count(ws, config)
    if ws and ws.master_count then return ws.master_count end
    if config and config.layout_options and config.layout_options.master_count then
        return config.layout_options.master_count
    end
    if config and config.master_count then return config.master_count end
    return 1
end

function layout.get_master_ratio(ws, config)
    if ws and ws.master_ratio then return ws.master_ratio end
    if config and config.layout_options and config.layout_options.master_ratio then
        return config.layout_options.master_ratio
    end
    if config and config.master_ratio then return config.master_ratio end
    return 0.5
end

function layout.split_rect(rect, n, vertical)
    local result = {}
    if vertical then
        local h = math.floor(rect.height / n)
        for i = 1, n do
            result[i] = {
                x = rect.x, y = rect.y + (i - 1) * h,
                width = rect.width, height = (i == n) and (rect.height - (i - 1) * h) or h
            }
        end
    else
        local w = math.floor(rect.width / n)
        for i = 1, n do
            result[i] = {
                x = rect.x + (i - 1) * w, y = rect.y,
                width = (i == n) and (rect.width - (i - 1) * w) or w,
                height = rect.height
            }
        end
    end
    return result
end

return layout