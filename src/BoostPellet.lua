--[[ CATcher
(c)2018 fluffy @ beesbuzz.biz

boost pellet
]]

local BoostPellet = {}

local util = require 'util'
local items = require 'items'
local palette = require 'palette'
local soundpool = require 'soundpool'

function BoostPellet.new(o, Game)
    local self = o or {}
    setmetatable(self, {__index=BoostPellet})

    local x, y = Game:getSpawnLocation()
    util.applyDefaults(self, {
        x = x,
        y = y,
        w = 8,
        h = 8,
        item = items.booster,
        color = palette.yellow,
        lifetime = math.random(5,15),
        strength = math.random(50,100),
        grabSound = soundpool.load('sound/pellet.ogg')
    })

    return self
end

function BoostPellet:update(dt)
    self.lifetime = self.lifetime - dt
    return self.lifetime <= 0
end

function BoostPellet:onCollect(cat)
    cat.vy = -math.abs(cat.vy) - self.strength
    soundpool.play(self.grabSound)
end

function BoostPellet:draw()
    love.graphics.setColor(unpack(self.color))
    love.graphics.draw(self.item.sprite, self.item.quad, self.x, self.y)
end

return BoostPellet
