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
        game = Game,
        x = x,
        y = y,
        w = 8,
        h = 8,
        item = items.booster,
        color = palette.yellow,
        lifetime = math.random(5,15),
        strength = math.random(50,100),
        grabSound = soundpool.load('sound/pellet.ogg'),
        age = 0
    })

    return self
end

function BoostPellet:update(dt)
    self.lifetime = self.lifetime - dt
    self.age = self.age + dt
    return self.lifetime <= 0
end

function BoostPellet:onCollect(cat)
    -- only be collectible if it's appeared for at least 2 frames
    if self.age <= 1/20 then
        return false
    end

    cat.vy = -math.abs(cat.vy) - self.strength
    soundpool.play(self.grabSound)
    self.game.score = self.game.score + 10
    return true
end

function BoostPellet:draw()
    love.graphics.setColor(unpack(self.color))
    love.graphics.draw(self.item.sprite, self.item.quad, self.x, self.y)
end

return BoostPellet
