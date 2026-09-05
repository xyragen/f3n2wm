local bit = require("bit")
local X11 = require("x11")
local config = require("config")

local MOD = {
    Shift = 1,
    Lock = 2,
    Control = 4,
    Mod1 = 8,
    Mod2 = 16,
    Mod3 = 32,
    Mod4 = 64,
    Mod5 = 128,
    M = 64,
    S = 1,
    C = 4,
    A = 8,
    Super = 64,
    Ctrl = 4,
    Alt = 8,
}

local keybindings = {}

function keybindings.install(wm)
    function wm:parse_keybinding(key_str)
        local parts = {}
        for part in key_str:gmatch("[^_]+") do
            parts[#parts+1] = part
        end
        if #parts == 0 then return nil, 0 end
        local mod_names = {}
        local key_parts = {}
        local i = 1
        while i <= #parts do
            if MOD[parts[i]] then
                mod_names[#mod_names+1] = parts[i]
                i = i + 1
            else
                for j = i, #parts do
                    key_parts[#key_parts+1] = parts[j]
                end
                break
            end
        end
        if #key_parts == 0 then return nil, 0 end
        local key_name = table.concat(key_parts, "_")
        local mod_mask = 0
        for _, mod_name in ipairs(mod_names) do
            local mask = MOD[mod_name]
            if mask then
                mod_mask = bit.bor(mod_mask, mask)
            end
        end
        return key_name, mod_mask
    end

    function wm:resolve_keycode(key_name)
        local keysym
        if config.keysyms and config.keysyms[key_name] then
            keysym = config.keysyms[key_name]
        else
            local upper = key_name:upper()
            if config.keysyms and config.keysyms[upper] then
                keysym = config.keysyms[upper]
            else
                if #key_name == 1 then
                    keysym = string.byte(key_name:upper())
                else
                    return nil
                end
            end
        end
        return X11.keysym_to_keycode(keysym)
    end

    function wm:setup_keybindings()
        local root = X11.root
        self.keybindings = {}

        if self.config.keybindings then
            for key_str, command in pairs(self.config.keybindings) do
                local key_name, mod_mask = self:parse_keybinding(key_str)
                if key_name then
                    local keycode = self:resolve_keycode(key_name)
                    if keycode then
                        X11.grab_key(root, keycode, mod_mask)
                        self.keybindings[keycode .. ":" .. mod_mask] = command
                    end
                end
            end
        end

        if self.config.mousebinds then
            for mouse_str, action in pairs(self.config.mousebinds) do
                local parts = {}
                for part in mouse_str:gmatch("[^_]+") do
                    parts[#parts+1] = part
                end
                if #parts >= 2 then
                    local button_str = parts[#parts]
                    local button_num = tonumber(button_str:match("Button(%d+)"))
                    if button_num then
                        local mod_mask = 0
                        for i = 1, #parts - 1 do
                            local mask = MOD[parts[i]]
                            if mask then
                                mod_mask = bit.bor(mod_mask, mask)
                            end
                        end
                        X11.grab_button(root, button_num, mod_mask)
                        self.keybindings["btn:" .. button_num .. ":" .. mod_mask] = action
                    end
                end
            end
        end
    end
end

return keybindings