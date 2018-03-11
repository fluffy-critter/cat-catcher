--[[
CATcher
(c)2018 fluffy at beesbuzz dot biz


platform randomizer effect
]]

local PlatformRandomizer = {}

local util = require 'util'
local Animator = require 'Animator'

function PlatformRandomizer.new(o)
    local self = o or {}

    util.applyDefaults(self, {
        timeBase = math.random()*5 + 1,
        timeJitter = math.random()*5,
        nextTime = 0,
    })

    setmetatable(self, {__index=PlatformRandomizer})
    return self
end

function PlatformRandomizer:update(dt, game)
    self.nextTime = self.nextTime - dt
    if self.nextTime <= 0 then
        self.nextTime = self.timeBase + math.random()*self.timeJitter
        game.animator:add({
            target = game.arena,
            property = 'destY',
            endPos = math.random(40, 140),
            easing = Animator.Easing.ease_inout
        })
    end
end

return PlatformRandomizer
