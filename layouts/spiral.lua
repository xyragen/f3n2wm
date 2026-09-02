local spiral = {}
spiral.name = "spiral"

function spiral.arrange(windows, rect, config)
    if #windows == 0 then return end

    local gap = config.gap_size or 0
    local border = config.border_width or 0
    local inset = gap + border

    local x, y = rect.x + inset, rect.y + inset
    local w, h = rect.width - inset * 2, rect.height - inset * 2

    if w < 100 or h < 100 then return end

    for i = 1, #windows do
        local win = windows[i]
        local ratio = 1 / (#windows - i + 2)
        local new_w, new_h, new_x, new_y

        if i == 1 then
            new_w = math.floor(w * 0.5)
            new_h = math.floor(h * 0.5)
            new_x, new_y = x, y
            x = x + new_w
            y = y + new_h
            w = w - new_w
            h = h - new_h
            w = math.floor(w / 0.5)
            h = math.floor(h / 0.5)
            x = x - math.floor(w * 0.5)
        else
            if i % 4 == 1 then
                new_w = math.floor(w * 0.5)
                new_h = math.floor(h * 0.5)
                new_x, new_y = x, y
                x = x + new_w
                w = w - new_w
                h = math.floor(h * 0.5)
                y = y + new_h
            elseif i % 4 == 2 then
                new_w = math.floor(w * 0.5)
                new_h = math.floor(h * 0.5)
                new_x, new_y = x, y
                w = math.floor(w * 0.5)
                y = y + new_h
                h = math.floor(h * 0.5)
                x = x - math.floor(w * 0.5) + new_w
            elseif i % 4 == 3 then
                new_w = math.floor(w * 0.5)
                new_h = math.floor(h * 0.5)
                new_x, new_y = x, y
                y = y + new_h
                h = h - new_h
            else
                new_w = math.floor(w * 0.5)
                new_h = math.floor(h * 0.5)
                new_x, new_y = x, y
                x = x + new_w
                w = w - new_w
                h = math.floor(h * 0.5)
            end
        end

        win:update_geometry(
            math.floor(new_x),
            math.floor(new_y),
            math.floor(new_w - inset),
            math.floor(new_h - inset)
        )
    end
end

return spiral
