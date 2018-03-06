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
    love.audio.newSource('sound/bgm2.ogg')
}

function love.load(args)
    cute.go(args)

    for _,music in ipairs(bgm) do
        music:setLooping(true)
        music:setVolume(1)
        music:setPitch(0.85)
        music:play()
    end
end

