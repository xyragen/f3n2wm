local window_events = require("events.window")
local input_events = require("events.input")

local events = {}

function events.install(wm)
    window_events.install(wm)
    input_events.install(wm)
end

return events