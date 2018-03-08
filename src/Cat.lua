--[[ CATcher
(c)2018 fluffy at beesbuzz dot biz


fur texture generator :)
]]

local Cat = {}

local util = require('util')

local palette = {
    -- {0,0,0},
    -- {255,255,255},
    -- {104,55,43},
    -- {112,164,178},
    -- {111,61,134},
    -- {88,141,67},
    -- {53,40,121},  -- background color
    {184,199,111},
    {111,79,37},
    -- {67,57,0},
    {154,103,89},
    {68,68,68},
    {108,108,108},
    {154,210,132},
    {108,94,181},
    {149,149,149}
}

local function randomColors()
    return util.shuffle(palette)
end

local furFunctions = {
    -- solid color
    function()
        local colors = randomColors()
        love.graphics.clear(unpack(colors[1]))
    end,

    -- calico
    function()
        love.graphics.clear(255,255,255)
        local colors = randomColors()
        for _=1,7 do
            love.graphics.setColor(unpack(colors[math.random(2)]))
            love.graphics.circle("fill", math.random(0,12), math.random(0,12), math.random(2,5))
        end
    end,

    -- stripes
    function()
        local colors = randomColors()
        for x=0,12 do
            love.graphics.setColor(unpack(colors[x%2 + 1]))
            love.graphics.line(x, 0, x, 21)
        end
    end
}

function Cat.makeTexture()
    local img = love.graphics.newCanvas(12, 21)

    local colors = util.shuffle(palette)

    img:renderTo(furFunctions[math.random(#furFunctions)])
    img:setFilter("nearest")

    return img
end

return Cat
