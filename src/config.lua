--[[
CATcher

(c)2018 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

config.lua - default user configuration/persistent settings

]]

local util = require 'util'

local overscan = 1.1

local config = {
    overscan = overscan,
    width = 320*overscan*3,
    height = 240*overscan*3,
    vsync = true,
}

local filePath = 'userconf.lua'

function config.save()
    local file = love.filesystem.newFile(filePath)
    file:open("w")

    file:write('return ')

    local function writeTable(tbl,pfx)
        file:write('{\n')
        local depth = '    ' .. pfx
        for k,v in pairs(tbl) do
            if type(v) == "number" or type(v) == "boolean" then
                file:write(depth .. string.format('%s=%s,\n', k, v))
            elseif type(v) == "string" then
                file:write(depth .. string.format('%s="%s",\n', k, v:gsub('"', '\\"')))
            elseif type(v) == "table" then
                file:write(depth .. string.format('%s=', k))
                writeTable(v, depth)
                file:write(',\n')
            end
        end
        file:write(pfx .. '}')
    end
    writeTable(config, '')
    print("Done saving config")
end

function config.load()
    print("Searching for config at " .. filePath)
    local ok, vals = xpcall(function()
        local chunk = love.filesystem.load(filePath)
        if chunk then
            return chunk()
        end
    end, function(err)
        print("Error loading config: " .. err)
    end)

    if ok and vals then
        util.applyValues(config, vals)
    end
end

config.load()

config.version = (love.filesystem.read("version") or "LOCAL BUILD"):gsub("%s+$","")

return config
