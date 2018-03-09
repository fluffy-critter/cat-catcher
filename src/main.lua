--[[ CATcher
(c)2018 fluffy @ beesbuzz.biz
]]

setmetatable(_G, {
    __newindex = function(_, name, _)
        error("attempted to write to global variable " .. name, 2)
    end
})

local cute = require('thirdparty.cute')
local util = require('util')
local config = require('config')
local profiler = config.profiler and require('profiler')

local Cat = require('Cat')

local bgm

local screen = {
    scale = 1,
    ox = 0,
    oy = 0
}

local cats = {}

function love.keypressed(key)
    if key == 'f' then
        config.fullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(config.fullscreen)
    end
end

function love.load(args)
    cute.go(args)

    bgm = {
        love.audio.newSource('sound/bgm1.ogg'),
        -- love.audio.newSource('sound/bgm2.ogg'),
        -- love.audio.newSource('sound/bgm3.ogg'),
        love.audio.newSource('sound/bgm4.ogg'),
    }

    for _,music in ipairs(bgm) do
        music:setLooping(true)
        music:setVolume(0.1)
        music:play()
    end

    love.window.setMode(config.width, config.height, {
        resizable = true,
        fullscreen = config.fullscreen,
        vsync = config.vsync,
        highdpi = config.highdpi,
        minwidth = 480,
        minheight = 480
    })

    table.insert(cats, Cat.new({
        x = 160,
        y = 100,
        vx = 30,
        state = Cat.State.playing,
        scale = 1
    }))
end

local time = 0
local speed = 1

local function setSpeed(s)
    speed = s
    for _,music in ipairs(bgm) do
        music:setPitch(speed)
    end
end

function love.resize(w, h)
    print("resize " .. w .. ' ' .. h)
    if not config.fullscreen then
        config.width, config.height = love.window.getMode()
        config.save()
    end
end

function love.update(dt)
    if profiler then profiler.attach("update", dt) end

    time = time + dt
    setSpeed(math.sin(time*.1)*0 + 1)

    local metronome = {
        beat = bgm[1]:tell()*64/bgm[1]:getDuration()
    }

    util.runQueue(cats, function(cat)
        return cat:update(dt, metronome)
    end)

    if profiler then profiler.detach() end
end

function love.draw()
    if profiler then profiler.attach("draw") end

    love.graphics.clear(120,105,196,255)

    local sw, sh = love.graphics.getDimensions()
    local tw, th = 320*config.overscan, 200*config.overscan
    local scale = math.min(sw/tw, sh/th)

    screen.w, screen.h = math.floor(320*scale), math.floor(200*scale)
    screen.x, screen.y = (sw - screen.w)/2, (sh - screen.h)/2

    if not screen.canvas or screen.canvas:getWidth() ~= screen.w or screen.canvas:getHeight() ~= screen.h then
        screen.canvas = love.graphics.newCanvas(screen.w, screen.h)
    end

    screen.canvas:renderTo(function()
        love.graphics.clear(64,49,141,255)

        love.graphics.push()
        love.graphics.scale(scale)

        util.runQueue(cats, function(cat)
            return cat:draw()
        end)

        love.graphics.pop()
    end)

    love.graphics.draw(screen.canvas, screen.x, screen.y)

    if profiler then
        profiler.detach()
        profiler.draw()
        profiler.attach("after")
    end
end
