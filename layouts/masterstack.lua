local masterstack = {}
masterstack.name = "master-stack"

function masterstack.arrange(windows, rect, config)
    if #windows == 0 then return end

    local gap = config.gap_size or 0
    local border = config.border_width or 0
    local inset = gap + border

    local usable_x = rect.x + inset
    local usable_y = rect.y + inset
    local usable_w = rect.width - (inset * 2)
    local usable_h = rect.height - (inset * 2)

    if usable_w < 100 or usable_h < 100 then return end

    local master_count = #windows
    local master_wins = 1
    if config and config.master_count then
        master_wins = config.master_count
    end
    master_wins = math.min(master_wins, #windows)

    local split = usable_w / 2
    local master_w = split
    local stack_w = usable_w - master_w
    local master_h = usable_h / master_wins
    local stack_h = usable_h

    for i = 1, #windows do
        local w = windows[i]
        if i <= master_wins then
            local y = usable_y + (i - 1) * master_h
            w:update_geometry(
                math.floor(usable_x),
                math.floor(y),
                math.floor(master_w - inset),
                math.floor(master_h - inset)
            )
        else
            local stack_idx = i - master_wins
            local stack_h_each = stack_h / (#windows - master_wins)
            local y = usable_y + (stack_idx - 1) * stack_h_each
            w:update_geometry(
                math.floor(usable_x + split),
                math.floor(y),
                math.floor(stack_w - inset),
                math.floor(stack_h_each - inset)
            )
        end
    end
end

return masterstack
