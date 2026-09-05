local debug = require("debug")

local engine = {}

engine.algorithms = {}

function engine.register_algorithm(name, fn)
    engine.algorithms[name] = fn
end

local function apply_gap(rect, gap)
    if not gap or gap <= 0 then return rect end
    return {
        x = rect.x + gap,
        y = rect.y + gap,
        width = math.max(1, rect.width - gap * 2),
        height = math.max(1, rect.height - gap * 2),
    }
end

local function split_rect(rect, direction, fracs, gap)
    local result = {}
    local total = 0
    for _, f in ipairs(fracs) do total = total + f end
    if total <= 0 then total = 1 end

    local offset = direction == "horizontal" and rect.y or rect.x
    local max = direction == "horizontal" and rect.height or rect.width

    for i, f in ipairs(fracs) do
        local size = math.floor(max * (f / total))
        local r = {}
        if direction == "horizontal" then
            r = { x = rect.x, y = offset, width = rect.width, height = size }
        else
            r = { x = offset, y = rect.y, width = size, height = rect.height }
        end
        if i == #fracs then
            local used = direction == "horizontal" and (offset - rect.y + size) or (offset - rect.x + size)
            local remain = max - used
            if direction == "horizontal" then r.height = r.height + remain
            else r.width = r.width + remain end
        end
        offset = offset + size
        result[i] = r
    end
    return result
end

function engine.slot_map(layout, windows, rect, cfg)
    local gap = (cfg and cfg.gap_size) or 0
    local direction = layout.direction or "vertical"
    local columns = layout.columns or {}
    local border = (cfg and cfg.border_width) or 0
    local inset = gap + border

    local usable = {
        x = rect.x + inset,
        y = rect.y + inset,
        width = math.max(1, rect.width - inset * 2),
        height = math.max(1, rect.height - inset * 2),
    }

    local win_count = #windows
    if win_count == 0 then return end

    local col_count = #columns
    if col_count == 0 then
        columns = { { size = 1, count = "fill" } }
        col_count = 1
    end

    local assignments = {}
    local win_idx = 1
    local fill_cols = {}
    for i, col in ipairs(columns) do
        assignments[i] = {}
        if col.count == "fill" then
            table.insert(fill_cols, i)
        else
            local n = math.min(tonumber(col.count) or 1, win_count - win_idx + 1)
            for _ = 1, n do
                if win_idx <= win_count then
                    table.insert(assignments[i], windows[win_idx])
                    win_idx = win_idx + 1
                end
            end
        end
    end
    if #fill_cols > 0 then
        while win_idx <= win_count do
            for _, fi in ipairs(fill_cols) do
                if win_idx <= win_count then
                    table.insert(assignments[fi], windows[win_idx])
                    win_idx = win_idx + 1
                end
            end
        end
    end

    local fracs = {}
    for _, col in ipairs(columns) do
        table.insert(fracs, tonumber(col.size) or (1 / col_count))
    end

    local col_rects = split_rect(usable, direction, fracs, gap)

    for i, col_r in ipairs(col_rects) do
        local wins = assignments[i]
        if wins and #wins > 0 then
            local sub_direction = (direction == "vertical") and "horizontal" or "vertical"
            local sub_fracs = {}
            for _ = 1, #wins do table.insert(sub_fracs, 1) end
            local sub_rects = split_rect(col_r, sub_direction, sub_fracs, gap)
            for j, w in ipairs(wins) do
                if sub_rects[j] then
                    w:update_geometry(
                        math.floor(sub_rects[j].x),
                        math.floor(sub_rects[j].y),
                        math.floor(sub_rects[j].width),
                        math.floor(sub_rects[j].height)
                    )
                end
            end
        end
    end
end

function engine.arrange(layout, windows, rect, cfg)
    if not layout or not windows or #windows == 0 then return end
    if layout.algorithm then
        local fn = engine.algorithms[layout.algorithm]
        if fn then
            local ok, err = pcall(fn, layout, windows, rect, cfg)
            if not ok then
                debug.error("layout", "algorithm '" .. layout.algorithm .. "' failed: " .. tostring(err))
            end
            return
        else
            debug.warn("layout", "unknown algorithm '" .. layout.algorithm .. "', falling back to slot-map")
        end
    end
    engine.slot_map(layout, windows, rect, cfg)
end

return engine