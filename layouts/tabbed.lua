local tabbed = {}
tabbed.name = "tabbed"

function tabbed.arrange(windows, rect, config)
    if #windows == 0 then return end

    local gap = config.gap_size or 0
    local border = config.border_width or 0
    local inset = gap + border
    local tab_height = 30

    local usable_x = rect.x + inset
    local usable_y = rect.y + inset + tab_height
    local usable_w = rect.width - inset * 2
    local usable_h = rect.height - inset * 2 - tab_height

    if usable_w < 100 or usable_h < 100 then
        usable_y = rect.y + inset
        usable_h = rect.height - inset * 2
        tab_height = 0
    end

    for i = 1, #windows do
        local w = windows[i]
        w:update_geometry(
            math.floor(usable_x),
            math.floor(usable_y),
            math.floor(usable_w),
            math.floor(usable_h)
        )
        w.tab_index = i
    end

    local ws = nil
    if windows[1] then
        local win = windows[1]
        if win.workspace then ws = win.workspace end
    end

    if ws and windows[#windows] then
        local focused = windows[#windows]
        for i = 1, #windows do
            if windows[i].focused then
                focused = windows[i]
                break
            end
        end
    end
end

return tabbed
