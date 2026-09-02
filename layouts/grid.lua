local grid = {}
grid.name = "grid"

function grid.arrange(windows, rect, config)
    if #windows == 0 then return end

    local gap = config.gap_size or 0
    local border = config.border_width or 0
    local inset = gap + border

    local usable_x = rect.x + inset
    local usable_y = rect.y + inset
    local usable_w = rect.width - inset * 2
    local usable_h = rect.height - inset * 2

    if usable_w < 100 or usable_h < 100 then return end

    local n = #windows
    local cols = math.ceil(math.sqrt(n))
    local rows = math.ceil(n / cols)

    local cell_w = math.floor(usable_w / cols)
    local cell_h = math.floor(usable_h / rows)

    local idx = 1
    for row = 1, rows do
        for col = 1, cols do
            if idx > n then break end
            local w = windows[idx]
            local x = usable_x + (col - 1) * cell_w
            local y = usable_y + (row - 1) * cell_h
            local cw = cell_w - inset
            local ch = cell_h - inset
            if col == cols and idx == n then
                cw = usable_w - (col - 1) * cell_w - inset
            end
            if row == rows then
                ch = usable_h - (row - 1) * cell_h - inset
            end
            w:update_geometry(
                math.floor(x),
                math.floor(y),
                math.floor(cw),
                math.floor(ch)
            )
            idx = idx + 1
        end
    end
end

return grid
