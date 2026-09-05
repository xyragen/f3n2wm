local hook = {}

hook.hooks = {}
hook.context = nil

function hook.set_context(ctx)
    hook.context = ctx
end

function hook.register(event_name, callback, priority)
    if not hook.hooks[event_name] then
        hook.hooks[event_name] = {}
    end
    local entry = {
        callback = callback,
        priority = priority or 100,
    }
    table.insert(hook.hooks[event_name], entry)
    table.sort(hook.hooks[event_name], function(a, b)
        return a.priority < b.priority
    end)
    return function()
        hook.unregister(event_name, callback)
    end
end

function hook.unregister(event_name, callback)
    if not hook.hooks[event_name] then return end
    for i, entry in ipairs(hook.hooks[event_name]) do
        if entry.callback == callback then
            table.remove(hook.hooks[event_name], i)
            return
        end
    end
end

function hook.fire(event_name, ...)
    if not hook.hooks[event_name] then return nil end
    local ctx = hook.context
    local should_cancel = false
    local cancel_return = nil

    for _, entry in ipairs(hook.hooks[event_name]) do
        local ok, result = pcall(entry.callback, ctx, ...)
        if not ok then
            print("HOOK ERROR: event=" .. tostring(event_name) .. " error=" .. tostring(result))
        elseif result == "cancel" or result == false then
            should_cancel = true
            cancel_return = result
        elseif result ~= nil then
            cancel_return = result
        end
    end

    if should_cancel then
        return cancel_return
    end
    return cancel_return
end

function hook.fire_with_data(event_name, data, ...)
    if not hook.hooks[event_name] then return nil end
    local ctx = hook.context
    local should_cancel = false
    local cancel_return = nil

    for _, entry in ipairs(hook.hooks[event_name]) do
        local ok, result = pcall(entry.callback, ctx, data, ...)
        if not ok then
            print("HOOK ERROR: event=" .. tostring(event_name) .. " error=" .. tostring(result))
        elseif result == "cancel" or result == false then
            should_cancel = true
            cancel_return = result
        elseif result ~= nil then
            cancel_return = result
        end
    end

    if should_cancel then
        return cancel_return
    end
    return cancel_return
end

function hook.wrap(event_name, fn)
    local original_hooks = hook.hooks[event_name]
    return function(ctx, ...)
        if original_hooks then
            for _, entry in ipairs(original_hooks) do
                entry.callback(ctx, ...)
            end
        end
        return fn(ctx, ...)
    end
end

hook.events = {
    "init",
    "startup",
    "shutdown",
    "reload",
    "window_open",
    "window_open_pre",
    "window_open_post",
    "window_close",
    "window_close_pre",
    "window_close_post",
    "window_focus",
    "window_focus_pre",
    "window_focus_post",
    "window_unfocus",
    "window_unfocus_pre",
    "window_unfocus_post",
    "window_map_request",
    "window_unmap",
    "window_destroy",
    "window_resize",
    "window_move",
    "window_maximize",
    "window_minimize",
    "window_fullscreen",
    "workspace_switch",
    "workspace_pre",
    "workspace_post",
    "workspace_add",
    "workspace_remove",
    "layout_apply",
    "layout_change",
    "layout_change_pre",
    "layout_change_post",
    "key_press",
    "key_release",
    "button_press",
    "button_release",
    "mouse_move",
    "mouse_enter",
    "mouse_leave",
    "client_message",
    "property_change",
    "screen_change",
    "config_reload",
    "config_reload_pre",
    "config_reload_post",
    "ipc_command",
    "ipc_command_pre",
    "ipc_command_post",
    "ipc_connect",
    "ipc_disconnect",
    "drag_start",
    "drag_update",
    "drag_stop",
    "resize_start",
    "resize_update",
    "resize_stop",
    "spawn",
    "spawn_pre",
    "spawn_post",
    "rule_match",
    "rule_apply",
    "cursor_enter",
    "cursor_leave",
    "focus_enter",
    "focus_leave",
    "desktop_init",
    "desktop_cleanup",
    "session_start",
    "session_end",
}

return hook
