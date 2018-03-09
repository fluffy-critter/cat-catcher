--[[ CATcher
(c)2018 fluffy at beesbuzz dot biz

Cats!
]]

local util = require('util')
local imagepool = require('imagepool')
local palette = require('palette')

local Cat = {}

Cat.State = util.enum("ready", "playing", "saved", "lost")

function Cat.new(o)
    local self = o or {}
    setmetatable(self, {__index=Cat})

    util.applyDefaults(self, {
        sprite = imagepool.load('gfx/cat.png', {nearest=true}),
        state = Cat.State.ready,
        color = palette.white,
        scale = 1,
        angle = 0,
        cx = 8,
        cy = 21,
        vx = 0,
        vy = 0,
        ax = 0,
        ay = 30,
        age = 0,
        dir = 1,
        points = 1,
        jump = 8,
        ofsY = 0
    })

    return self
end

function Cat:update(dt, Game)
    if self.state == Cat.State.ready or self.state == Cat.State.saved then
        -- Kittycat dance
        local phase = Game.metronome.beat + 0.25
        local ramp = util.smoothStep(math.min((phase % 1)*2, 1))
        local bounce = ramp*(1 - ramp)*4

        local ta = ((math.floor(phase) % 2)*2 - 1)*0.4
        self.angle = util.lerp(-ta, ta, ramp/2)
        self.ofsY = self.jump*bounce
        self.x = self.x + bounce*dt*self.vx

        if self.x - self.cx*self.scale > 320 then
            print("byeeee!")
            return true
        end
    elseif self.state == Cat.State.playing then
        self.ofsY = util.lerp(self.ofsY, 0, dt)

        self.x = self.x + (self.vx + 0.5*self.ax*dt)*dt
        self.y = self.y + (self.vy + 0.5*self.ay*dt)*dt

        self.vx = self.vx + self.ax*dt
        self.vy = self.vy + self.ay*dt

        self.angle = 0 -- TODO

        -- if it hits the floor, it loses
        if self.y >= 200 then
            self.vy = 0
            self.state = Cat.State.lost
            self.y = 200
            self.vx = -30
        end
    elseif self.state == Cat.State.lost then
        self.angle = math.sin(Game.metronome.beat*math.pi)*.1
        self.x = self.x + self.vx*dt

        if self.x + self.cx*self.scale < 0 then
            print("byeeee :(")
            return true
        end
    end

    if self.vx > 0 then
        dir = 1
    elseif self.vx < 0 then
        dir = -1
    end
end

function Cat:draw()
    love.graphics.setColor(unpack(self.color))
    love.graphics.setBlendMode("alpha", "alphamultiply")
    love.graphics.draw(self.sprite, self.x, self.y - self.ofsY*self.scale,
        self.angle, self.scale*self.dir, self.scale, self.cx, self.cy)
end

return Cat
