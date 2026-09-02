local monocle = {}
monocle.name = "monocle"

function monocle.arrange(windows, rect, config)
    if #windows == 0 then return end

    local gap = config.gap_size or 0
    local border = config.border_width or 0
    local inset = gap + border

    local usable_x = rect.x + inset
    local usable_y = rect.y + inset
    local usable_w = rect.width - inset * 2
    local usable_h = rect.height - inset * 2

    if usable_w < 100 or usable_h < 100 then return end

    for i = 1, #windows do
        local w = windows[i]
        w:update_geometry(
            math.floor(usable_x),
            math.floor(usable_y),
            math.floor(usable_w),
            math.floor(usable_h)
        )
    end
end

return monocle
