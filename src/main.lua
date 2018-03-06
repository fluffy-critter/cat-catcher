--[[ CATcher
(c)2018 fluffy @ beesbuzz.biz
]]

setmetatable(_G, {
    __newindex = function(_, name, _)
        error("attempted to write to global variable " .. name, 2)
    end
})

local cute = require('thirdparty.cute')

local bgm = {
    love.audio.newSource('sound/bgm1.ogg'),
    love.audio.newSource('sound/bgm2.ogg'),
}

local cat = love.graphics.newImage('gfx/cat.png')

function love.load(args)
    cute.go(args)

    for _,music in ipairs(bgm) do
        music:setLooping(true)
        music:setVolume(1)
        music:setPitch(0.85)
        music:play()
    end

    cat:setFilter("nearest", "nearest")
end

function love.draw()
    love.graphics.clear(0,0,0,255)

    local sw, sh = love.graphics.getDimensions()
    local scale = math.min(sw/320, sh/200)
    love.graphics.scale(scale)

    local phase = math.floor(bgm[1]:tell()*64/bgm[1]:getDuration()) % 2
    local angle = (phase*2 - 1)*.4
    print(angle)
    love.graphics.draw(cat, 160, 100, angle, 1, 1, 8, 24)
end
