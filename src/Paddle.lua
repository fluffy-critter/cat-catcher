--[[ CATcher
(c)2018 fluffy at beesbuzz dot biz

Paddle!
]]

local Paddle = {}

local palette = require('palette')
local util = require('util')

function Paddle.new(o)
    local self = o or {}
    setmetatable(self, {__index=Paddle})

    util.applyDefaults(self, {
        x = 160 - 24,
        w = 48,
        h = 4,
        y = 200 - 4 - 16,
        vx = 0,
        friction = 0.001,
        bounce = 0.05,
        elasticity = 0.95,
        color = palette.lightblue,
    })

    return self
end

function Paddle:impulse(vx)
    self.vx = self.vx + vx
end

function Paddle:update(dt)
    -- TODO handle keyboard and/or joystick

    self.x = self.x + self.vx*dt
    self.vx = self.vx*math.pow(self.friction, dt)

    if self.x < 0 then
        self.x = 0
        self.vx = math.abs(self.vx)*self.bounce
    end

    if self.x + self.w > 320 then
        self.x = 320 - self.w
        self.vx = -math.abs(self.vx)*self.bounce
    end
end

function Paddle:draw()
    love.graphics.setColor(unpack(self.color))
    love.graphics.setBlendMode("alpha", "alphamultiply")
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

return Paddle
