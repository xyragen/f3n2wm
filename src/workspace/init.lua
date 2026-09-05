local object = require("workspace.object")
local mgr_module = require("workspace.manager")

local workspace = {}

workspace.wm = nil
workspace.current_ws = 1

function workspace.set_wm(wm)
    workspace.wm = wm
end

workspace.Workspace = object.Workspace
workspace.WorkspaceManager = mgr_module.WorkspaceManager

return workspace