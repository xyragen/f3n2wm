local window = {}

window.windows = {}
window.wm = nil

function window.set_wm(wm)
    window.wm = wm
end

function window.register(id)
    local w = window.Window:new(id)
    window.windows[id] = w
    return w
end

function window.unregister(id)
    window.windows[id] = nil
end

function window.get(id)
    return window.windows[id]
end

function window.is_registered(id)
    return window.windows[id] ~= nil
end

function window.all()
    return window.windows
end

function window.count()
    local count = 0
    for _ in pairs(window.windows) do count = count + 1 end
    return count
end

function window.get_visible()
    local result = {}
    for id, w in pairs(window.windows) do
        if w.visible then result[#result+1] = w end
    end
    return result
end

function window.get_tiled()
    local result = {}
    for id, w in pairs(window.windows) do
        if w.tiled and w.visible and not w.floating and not w.fullscreen then
            result[#result+1] = w
        end
    end
    return result
end

function window.get_floating()
    local result = {}
    for id, w in pairs(window.windows) do
        if w.floating and w.visible then result[#result+1] = w end
    end
    return result
end

function window.get_fullscreen()
    local result = {}
    for id, w in pairs(window.windows) do
        if w.fullscreen and w.visible then result[#result+1] = w end
    end
    return result
end

function window.get_focused()
    if not window.wm or not window.wm.workspaces then return nil end
    local ws = window.wm.workspaces:get_current()
    if not ws then return nil end
    if ws.focused then return window.windows[ws.focused] end
    return nil
end

function window.get_urgent()
    local result = {}
    for id, w in pairs(window.windows) do
        if w.urgent then result[#result+1] = w end
    end
    return result
end

return window