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

local bgm

local cat = {
    sprite = love.graphics.newImage('gfx/cat.png'),
    angle = 0,
    scale = 2,
    cx = 8,
    cy = 21,
    x = 160,
    y = 140,
    ofsY = 0
}

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
        music:setVolume(1)
        music:play()
    end

    cat.sprite:setFilter("nearest", "nearest")
end

local time = 0
local speed = 1

local function setSpeed(s)
    speed = s
    for _,music in ipairs(bgm) do
        music:setPitch(speed)
    end
end

function love.update(dt)
    time = time + dt
    setSpeed(math.sin(time*.1)*0 + 1)

    local phase = bgm[1]:tell()*64/bgm[1]:getDuration() + 0.1
    local ta = ((math.floor(phase) % 2)*2 - 1)*.4

    local ramp = util.smoothStep(math.min((phase % 1)*3, 1))
    cat.angle = util.lerp(cat.angle, ta, ramp/2)
    cat.ofsY = (ramp*(1-ramp))*30
end

function love.draw()
    love.graphics.clear(0,0,0,255)

    local sw, sh = love.graphics.getDimensions()
    local scale = math.min(sw/320, sh/200)
    love.graphics.scale(scale)

    love.graphics.draw(cat.sprite, cat.x, cat.y - cat.ofsY, cat.angle, cat.scale, cat.scale, cat.cx, cat.cy)
end
