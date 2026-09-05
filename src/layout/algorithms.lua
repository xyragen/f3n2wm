local engine = require("layout.engine")

local algorithms = {}

function algorithms.spiral(layout, windows, rect, cfg)
    local gap = (cfg and cfg.gap_size) or 0
    local border = (cfg and cfg.border_width) or 0
    local inset = gap + border
    local ratio = tonumber(layout.ratio) or 0.5

    local x = rect.x + inset
    local y = rect.y + inset
    local w = math.max(1, rect.width - inset * 2)
    local h = math.max(1, rect.height - inset * 2)

    for i = 1, #windows do
        local win = windows[i]
        win:update_geometry(math.floor(x), math.floor(y), math.floor(w), math.floor(h))
        if i < #windows then
            if i % 2 == 1 then
                local new_w = math.floor(w * ratio)
                x = x + (w - new_w)
                w = new_w
            else
                local new_h = math.floor(h * ratio)
                y = y + (h - new_h)
                h = new_h
            end
        end
    end
end

function algorithms.monocle(layout, windows, rect, cfg)
    local gap = (cfg and cfg.gap_size) or 0
    local border = (cfg and cfg.border_width) or 0
    local inset = gap + border
    for _, w in ipairs(windows) do
        w:update_geometry(
            math.floor(rect.x + inset),
            math.floor(rect.y + inset),
            math.floor(math.max(1, rect.width - inset * 2)),
            math.floor(math.max(1, rect.height - inset * 2))
        )
    end
end

engine.register_algorithm("spiral", algorithms.spiral)
engine.register_algorithm("monocle", algorithms.monocle)

return algorithms