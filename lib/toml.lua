local toml = {}

local char_to_hex = function(c)
    if c == " " then return "+" end
    local n = string.byte(c)
    return string.format("%%%02X", n)
end

local urlEncode = function(str)
    if str == nil then return "" end
    local chars = " !\"#<>'()*+,{}/[]:;|=?@^`"
    local res = ""
    for i = 1, #str do
        local c = str:sub(i, i)
        if chars:find(c, 1, true) then
            res = res .. char_to_hex(c)
        else
            res = res .. c
        end
    end
    return res
end

local unescape = function(s, i, quoted)
    local c = s:sub(i, i)
    if c == 'n' then return '\n'
    elseif c == 'r' then return '\r'
    elseif c == 't' then return '\t'
    elseif c == 'b' then return '\b'
    elseif c == 'f' then return '\f'
    elseif c == '\\' then return '\\'
    elseif c == '"' then
        if quoted then return '"' end
    elseif c == "'" then return "'"
    elseif c == '/' then return "/"
    elseif c == 'u' then
        local h = s:sub(i+1, i+4)
        return string.char(tonumber(h, 16))
    elseif c == 'U' then
        local h = s:sub(i+1, i+8)
        return string.char(tonumber(h, 16))
    end
    return c
end

local parse_chars = function(str, pos, quote, allow_continuation)
    local chars = {}
    local next_quote = quote
    if allow_continuation then
        next_quote = quote .. quote
    end
    local i = pos
    local len = #str
    while i <= len do
        local c = str:sub(i, i)
        if c == quote then
            if allow_continuation and str:sub(i+1, i+1) == quote then
                if str:sub(i+2, i+2) == quote then
                    i = i + 3
                    return table.concat(chars), i
                else
                    chars[#chars+1] = quote
                    i = i + 2
                end
            else
                i = i + 1
                return table.concat(chars), i
            end
        elseif c == '\\' then
            local next_c = str:sub(i+1, i+1)
            if next_c == quote or next_c == '\\' then
                chars[#chars+1] = next_c
                i = i + 2
            elseif next_c == 'n' then
                chars[#chars+1] = '\n'
                i = i + 2
            elseif next_c == 'r' then
                chars[#chars+1] = '\r'
                i = i + 2
            elseif next_c == 't' then
                chars[#chars+1] = '\t'
                i = i + 2
            elseif next_c == 'b' then
                chars[#chars+1] = '\b'
                i = i + 2
            elseif next_c == 'f' then
                chars[#chars+1] = '\f'
                i = i + 2
            elseif next_c == 'u' then
                local h = str:sub(i+2, i+5)
                chars[#chars+1] = string.char(tonumber(h, 16))
                i = i + 6
            elseif next_c == 'U' then
                local h = str:sub(i+2, i+7)
                chars[#chars+1] = string.char(tonumber(h, 16))
                i = i + 8
            else
                chars[#chars+1] = c
                chars[#chars+1] = next_c
                i = i + 2
            end
        else
            chars[#chars+1] = c
            i = i + 1
        end
    end
    return nil, pos
end

local parse_basic_str = function(str, i)
    local res, next_pos = parse_chars(str, i, '"')
    if res == nil then error("Expected closing quote") end
    return res, next_pos
end

local parse_basic_str_multiline = function(str, i)
    local chars = {}
    local line_start = i
    local len = #str
    while i <= len do
        local c = str:sub(i, i)
        if c == '"' then
            if str:sub(i+1, i+1) == '"' and str:sub(i+2, i+2) == '"' then
                return table.concat(chars), i + 3
            end
        end
        if c == '\\' then
            local next_c = str:sub(i+1, i+1)
            if next_c == 'u' then
                local h = str:sub(i+2, i+5)
                chars[#chars+1] = string.char(tonumber(h, 16))
                i = i + 6
            elseif next_c == 'U' then
                local h = str:sub(i+2, i+7)
                chars[#chars+1] = string.char(tonumber(h, 16))
                i = i + 8
            elseif next_c == '"' then
                i = i + 2
            elseif next_c == '\\' then
                chars[#chars+1] = '\\'
                i = i + 2
            elseif next_c == 'n' then
                i = i + 2
            elseif next_c == 'r' then
                chars[#chars+1] = '\r'
                i = i + 2
            elseif next_c == 't' then
                chars[#chars+1] = '\t'
                i = i + 2
            elseif next_c == 'b' then
                chars[#chars+1] = '\b'
                i = i + 2
            elseif next_c == 'f' then
                chars[#chars+1] = '\f'
                i = i + 2
            elseif next_c == '/' then
                i = i + 2
            else
                chars[#chars+1] = c
                i = i + 2
            end
        elseif c == '\n' then
            chars[#chars+1] = '\n'
            i = i + 1
        elseif c == '\r' then
            i = i + 1
            if str:sub(i, i) == '\n' then
                i = i + 1
            end
            chars[#chars+1] = '\n'
        else
            chars[#chars+1] = c
            i = i + 1
        end
    end
    return nil, line_start
end

local parse_literal_str = function(str, i)
    local chars = {}
    local len = #str
    while i <= len do
        local c = str:sub(i, i)
        if c == "'" then
            return table.concat(chars), i + 1
        end
        if c == '\n' or c == '\r' then
            error("Literal string cannot span lines")
        end
        chars[#chars+1] = c
        i = i + 1
    end
    return nil, i
end

local parse_literal_str_multiline = function(str, i)
    local chars = {}
    local len = #str
    while i <= len do
        local c = str:sub(i, i)
        if c == "'" then
            if str:sub(i+1, i+1) == "'" and str:sub(i+2, i+2) == "'" then
                return table.concat(chars), i + 3
            end
        end
        if c == '\n' then
            chars[#chars+1] = '\n'
        elseif c == '\r' then
            if str:sub(i+1, i+1) == '\n' then
                i = i + 1
            end
            chars[#chars+1] = '\n'
        else
            chars[#chars+1] = c
        end
        i = i + 1
    end
    return nil, i
end

local find_line_end = function(str, pos)
    local len = #str
    while pos <= len do
        local c = str:sub(pos, pos)
        if c == '\n' then
            return pos - 1
        end
        if c == '\r' then
            return pos - 1
        end
        pos = pos + 1
    end
    return len
end

local extract_string = function(str, i)
    local c = str:sub(i, i)
    if c == '"' then
        if str:sub(i+1, i+2) == '""' then
            return parse_basic_str_multiline(str, i + 3)
        else
            return parse_basic_str(str, i + 1)
        end
    elseif c == "'" then
        if str:sub(i+1, i+2) == "''" then
            return parse_literal_str_multiline(str, i + 3)
        else
            return parse_literal_str(str, i + 1)
        end
    else
        error("Invalid string at position " .. i)
    end
end

local whitespace_aware_extract_string = function(str, i)
    local res, next_pos = extract_string(str, i)
    return res, next_pos
end

local hex2dec = function(h, l)
    local n = 0
    for i = l, 1, -1 do
        local c = h:sub(i, i)
        local d = tonumber(c, 16)
        n = n + d * (16 ^ (l - i))
    end
    return n
end

local parse_value = function(str, i)
    local c = str:sub(i, i)
    if c == '"' or c == "'" then
        return extract_string(str, i)
    elseif c == 't' or c == 'f' then
        if str:sub(i, i+3) == 'true' then
            return true, i + 4
        elseif str:sub(i, i+4) == 'false' then
            return false, i + 5
        end
        error("Invalid boolean at position " .. i)
    elseif c == '[' or c == '{' then
        return nil, i
    else
        local num = ''
        local len = #str
        local j = i
        while j <= len do
            c = str:sub(j, j)
            if c == ' ' or c == '\n' or c == '\r' or c == '\t' or
               c == ']' or c == '}' or c == ',' or c == '#' then
                break
            end
            num = num .. c
            j = j + 1
        end
        if num == 'true' then return true, j
        elseif num == 'false' then return false, j
        elseif num == 'inf' or num == '+inf' then return math.huge, j
        elseif num == '-inf' or num == '+inf' then return -math.huge, j
        elseif num == 'nan' or num == '+nan' then return 0/0, j
        elseif num == '-nan' then return 0/0, j
        end
        local n
        if num:sub(1, 2) == '0x' or num:sub(1, 3) == '-0x' or num:sub(1, 3) == '+0x' then
            local sign = ''
            if num:sub(1, 1) == '-' then sign = '-' end
            num = num:gsub('[%+%-]', '')
            num = num:sub(3)
            num = num:gsub('_', '')
            n = tonumber(num, 16)
            if n == nil then error("Invalid hex number: " .. num) end
            if sign == '-' then n = -n end
        else
            local num_clean = num:gsub('[%+%-]', '')
            num_clean = num_clean:gsub('_', '')
            if num_clean:find('%.') or num_clean:find('e') or num_clean:find('E') then
                n = tonumber(num)
                if n == nil then error("Invalid number at position " .. i) end
            else
                n = tonumber(num)
                if n == nil then error("Invalid number at position " .. i) end
            end
        end
        return n, j
    end
    return nil, i
end

local spaces = function(str, i)
    local len = #str
    while i <= len do
        local c = str:sub(i, i)
        if c ~= ' ' and c ~= '\t' then
            break
        end
        i = i + 1
    end
    return i
end

local parse_key = function(str, i)
    local c = str:sub(i, i)
    if c == '"' or c == "'" then
        local key, next_pos = extract_string(str, i)
        return key, next_pos
    else
        local len = #str
        local j = i
        while j <= len do
            c = str:sub(j, j)
            if c == '=' or c == ' ' or c == '\n' or c == '\r' or c == '\t' then
                break
            end
            j = j + 1
        end
        if j == i then
            error("Invalid key at position " .. i)
        end
        return str:sub(i, j-1), j
    end
end

local parse_array = function(str, i)
    local result = {}
    local len = #str
    i = spaces(str, i + 1)
    if str:sub(i, i) == ']' then
        return result, i + 1
    end
    while i <= len do
        i = spaces(str, i)
        if str:sub(i, i) == '#' then
            i = find_line_end(str, i) + 1
            i = spaces(str, i)
        end
        local c = str:sub(i, i)
        if c == ']' then
            return result, i + 1
        end
        local val, next_pos = parse_value(str, i)
        if val == nil then
            local sub, next_i = parse_array(str, i)
            result[#result+1] = sub
            i = next_i
        else
            result[#result+1] = val
            i = next_pos
        end
        i = spaces(str, i)
        c = str:sub(i, i)
        if c == '#' then
            i = find_line_end(str, i) + 1
            i = spaces(str, i)
            c = str:sub(i, i)
        end
        if c == ',' then
            i = i + 1
        elseif c == ']' then
            return result, i + 1
        end
    end
    return result, i
end

local parse_inline_table = function(str, i)
    local result = {}
    local len = #str
    i = i + 1
    local parsed_one = false
    while i <= len do
        i = spaces(str, i)
        if str:sub(i, i) == '#' then
            i = find_line_end(str, i) + 1
        end
        local c = str:sub(i, i)
        if c == '}' then
            return result, i + 1
        end
        if parsed_one then
            if c ~= ',' then
                error("Expected , or } at position " .. i)
            end
            i = i + 1
            i = spaces(str, i)
        end
        parsed_one = true
        local key, key_end = parse_key(str, i)
        i = key_end
        i = spaces(str, i)
        c = str:sub(i, i)
        if c ~= '=' then
            error("Expected = at position " .. key_end)
        end
        i = spaces(str, i + 1)
        local val, next_pos = parse_value(str, i)
        if val == nil then
            if str:sub(next_pos, next_pos) == '[' then
                local arr, arr_end = parse_array(str, next_pos)
                result[key] = arr
                i = arr_end
            else
                local sub, sub_end = parse_inline_table(str, next_pos)
                result[key] = sub
                i = sub_end
            end
        else
            result[key] = val
            i = next_pos
        end
        i = spaces(str, i)
    end
    return result, i
end

local parse_simple_key = function(str, i)
    local c = str:sub(i, i)
    if c == '"' or c == "'" then
        return extract_string(str, i)
    end
    local len = #str
    local j = i
    while j <= len do
        local ch = str:sub(j, j)
        if ch == ' ' or ch == '\n' or ch == '\r' or ch == '\t' or
           ch == '.' or ch == '[' or ch == ']' or ch == '#' or ch == '=' then
            break
        end
        j = j + 1
    end
    if j == i then
        error("Invalid key at position " .. i)
    end
    return str:sub(i, j-1), j
end

local parse_dotted_key = function(str, i)
    local result = {}
    while true do
        local key, next_pos = parse_simple_key(str, i)
        result[#result+1] = key
        i = next_pos
        i = spaces(str, i)
        if str:sub(i, i) == '.' then
            i = i + 1
            i = spaces(str, i)
        else
            return result, i
        end
    end
end

local skip_comment = function(str, i)
    local c = str:sub(i, i)
    if c ~= '#' then return i end
    return find_line_end(str, i) + 1
end

local parser = {}

function parser.parse(str)
    local result = {}
    local current_table = result
    local len = #str
    local i = 1
    while i <= len do
        local c = str:sub(i, i)
        if c == '\n' or c == '\r' then
            i = i + 1
        elseif c == ' ' or c == '\t' then
            i = i + 1
        elseif c == '#' then
            i = skip_comment(str, i)
        elseif c == '[' then
            if str:sub(i+1, i+1) == '[' then
                local key, next_pos = parse_dotted_key(str, i + 2)
                i = next_pos
                i = spaces(str, i)
                if str:sub(i, i) ~= ']' then
                    error("Expected ] at position " .. i)
                end
                i = i + 1
                i = spaces(str, i)
                if str:sub(i, i) ~= ']' then
                    error("Expected ]] at position " .. i)
                end
                i = i + 1
            else
                local key, next_pos = parse_dotted_key(str, i + 1)
                i = next_pos
                i = spaces(str, i)
                if str:sub(i, i) ~= ']' then
                    error("Expected ] at position " .. i)
                end
                i = i + 1
                local t = result
                for _, k in ipairs(key) do
                    if type(k) == "number" then k = tostring(k) end
                    if t[k] == nil then
                        t[k] = {}
                    end
                    t = t[k]
                end
                current_table = t
            end
            i = skip_comment(str, i)
        else
            local key, key_end = parse_dotted_key(str, i)
            i = key_end
            i = spaces(str, i)
            c = str:sub(i, i)
            if c ~= '=' then
                error("Expected = at position " .. i)
            end
            i = i + 1
            i = spaces(str, i)
            i = skip_comment(str, i)
            local val, next_pos = parse_value(str, i)
            if val == nil then
                local sub
                if str:sub(next_pos, next_pos) == '[' then
                    sub, next_pos = parse_array(str, next_pos)
                else
                    sub, next_pos = parse_inline_table(str, next_pos)
                end
                val = sub
                i = next_pos
            else
                i = next_pos
            end
            local t = result
            for j = 1, #key - 1 do
                local k = key[j]
                if type(k) == "number" then k = tostring(k) end
                if t[k] == nil then
                    t[k] = {}
                end
                t = t[k]
            end
            local last_key = key[#key]
            if type(last_key) == "number" then last_key = tostring(last_key) end
            t[last_key] = val
            i = skip_comment(str, i)
        end
    end
    return result
end

function toml.parse(str)
    return parser.parse(str)
end

function toml.load(path)
    local f = io.open(path, "r")
    if not f then return nil, "Could not open config file: " .. path end
    local content = f:read("*a")
    f:close()
    return toml.parse(content)
end

return toml
