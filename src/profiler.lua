--[[
CATcher

(c)2018 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Profiler thingus. Inspired by classic 'CRT-scanline' profiling techniques.

]]

local util = require 'util'
local bit = require 'bit'

local profiler = {}

local font = love.graphics.newFont(16)

local context
local stats = {
    counts = {},
    total = 0
}

local totalTime = 0
local targetTime = 0

local contextTimes = {}

local contextColors = {
    update = {255,0,0,127},
    draw = {0,255,0,127},
    after = {0,0,255}
}

local colors = {}
local function colorHash(str)
    local h = 0xdeadbeef
    for i = 1, #str do
        h = bit.bxor(bit.ror(h, 3), str:byte(i)*32452867)
    end
    return {h % 256, math.floor(h/256) % 256, math.floor(h/65536) % 256}
end

local lastTime

local function hook()
    local info = debug.getinfo(2)
    if info then
        local where = context .. ':' .. tostring(info.name) .. info.source .. ':' .. info.linedefined
        if not colors[where] then
            colors[where] = {
                context = contextColors[context],
                id = colorHash(where)
            }
        end
        local now = love.timer.getTime()
        local delta = now - lastTime
        lastTime = now
        stats.counts[where] = (stats.counts[where] or 0) + delta
        stats.total = stats.total + delta
    end
end

function profiler.attach(name)
    if context then
        profiler.detach()
    end

    context = name
    lastTime = love.timer.getTime()

    contextTimes[name] = contextTimes[name] or {}
    contextTimes[name].start = lastTime

    debug.sethook(hook, "", 25)
end

function profiler.detach()
    debug.sethook()

    if context then
        contextTimes[context].total =
            (contextTimes[context].total or 0) + love.timer.getTime() - contextTimes[context].start
    end

    context = nil
    lastTime = nil
end

function profiler.draw()
    if stats.total == 0 then
        return
    end

    love.graphics.push("all")
    love.graphics.origin()
    love.graphics.setBlendMode("alpha")

    -- draw the function timings
    local y = 0
    local dy = love.graphics.getHeight()/totalTime
    for k,count in util.spairs(stats.counts, function(t,a,b) return t[b] < t[a] end) do
        local h = dy * count

        love.graphics.setColor(unpack(colors[k].context))
        love.graphics.rectangle("fill", 0, y, 15, h)

        if h > 8 then
            love.graphics.setFont(font)
            love.graphics.setColor(0,0,0)
            love.graphics.print(k, 16, y+1)
            love.graphics.setColor(255,255,255)
            love.graphics.print(k, 14, y-1)
            love.graphics.setColor(unpack(colors[k].id))
            love.graphics.print(k, 15, y)
        end
        y = y + h
    end

    -- smoothing
    for k,v in pairs(stats.counts) do
        stats.counts[k] = v*.9
    end
    stats.total = stats.total*.9

    -- draw the context timings
    totalTime = totalTime*.9 + love.timer.getDelta()
    y = 0
    local x = love.graphics.getWidth() - 15
    dy = love.graphics.getHeight()/totalTime
    for k,v in pairs(contextTimes) do
        love.graphics.setColor(unpack(contextColors[k]))
        local h = dy*v.total
        love.graphics.rectangle("fill", x, y, 15, h)
        y = y + h
    end

    -- smoothing
    for k,v in pairs(contextTimes) do
        contextTimes[k].total = v.total*.9
    end

    -- draw the 60FPS boundary line
    love.graphics.setColor(255,255,0,127)
    y = love.graphics.getHeight()*targetTime/totalTime
    love.graphics.line(x - 32, y, x + 15, y)
    targetTime = targetTime*.9 + 1/60

    love.graphics.pop()
end

return profiler
