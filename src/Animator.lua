--[[
CATcher

(c)2018 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Animation manager

Properties used on the animation objects:

easing - easing function
duration - time in seconds

target - target sbject
property - which propertybag to tween on the target (default: "pos")
startPos - starting position (defaults to current target position)
endPos - ending position (defaults to start position)

onStart - callback to call when animation initiates (param: target)
onComplete - callback to call when finished (param: target)

startPos and endPos need to have the same indices.

]]

local util = require 'util'

local Animator = {}

-- easing functions, all in the form of (from, to, t) where t=0..1
Animator.Easing = {
    linear = util.lerp,
    ease_inout = function(a, b, x)
        return a + (b - a)*util.smoothStep(x)
    end,
    ease_in = function(a, b, x)
        return a + (b - a)*x*x
    end,
    ease_out = function(a, b, x)
        return b + (a - b)*(1 - x)*(1 - x)
    end
}

function Animator.new(o)
    local self = o or {}
    setmetatable(self, {__index = Animator})

    util.applyDefaults(self, {
        queue = {}
    })

    return self
end

-- Add an animation to the system, preempting any animations that match the condition function
function Animator:add(anim, preempt)
    if preempt then
        util.runQueue(self.queue, preempt)
    end

    util.applyDefaults(anim, {
        easing = Animator.Easing.linear,
        duration = 1,
        onComplete = nil,
        now = 0,
        property = "pos"
    })

    table.insert(self.queue, anim)
end

function Animator:update(dt)
    util.runQueue(self.queue, function(anim)
        if anim.onStart then
            anim:onStart()
            anim.onStart = nil
        end

        if not anim.startPos then
            anim.startPos = anim.target[anim.property]
        end
        if not anim.endPos then
            anim.endPos = anim.startPos
        end

        anim.now = anim.now + dt
        if anim.now >= anim.duration then
            anim.target[anim.property] = anim.endPos
            if anim.onComplete then
                anim:onComplete(anim.target)
                anim.onComplete = nil
            end

            return true
        else
            local t = anim.now / anim.duration
            anim.target[anim.property] = anim.easing(anim.startPos, anim.endPos, t)
        end
    end)
end

function Animator:isFinished()
    return self.now >= self.duration
end

return Animator
