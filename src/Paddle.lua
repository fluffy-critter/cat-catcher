--[[ CATcher
(c)2018 fluffy at beesbuzz dot biz

Paddle!
]]

local Paddle = {}

local palette = require 'palette'
local util = require 'util'

function Paddle.new(o)
    local self = o or {}
    setmetatable(self, {__index=Paddle})

    util.applyDefaults(self, {
        x = 160 - 24,
        w = 48,
        h = 4,
        y = 200 - 4 - 16,
        vx = 0,
        keyAX = 2000,
        friction = 0.0005,
        bounce = 0.05,
        color = palette.lightblue,
    })

    return self
end

function Paddle:impulse(vx)
    self.vx = self.vx + vx
end

function Paddle:update(dt)
    local ax = 0
    if love.keyboard.isDown('right') then
        ax = ax + self.keyAX
    end
    if love.keyboard.isDown('left') then
        ax = ax - self.keyAX
    end

    self.x = self.x + (self.vx + ax*0.5*dt)*dt
    self.vx = self.vx*math.pow(self.friction, dt) + ax*dt

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
