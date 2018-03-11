--[[ CATcher
(c)2018 fluffy @ beesbuzz.biz
]]

local util = require 'util'

local bgm = {
    tracks = {
        bass = love.audio.newSource('sound/bgm1.ogg'),
        doot = love.audio.newSource('sound/bgm2.ogg'),
        pad = love.audio.newSource('sound/bgm3.ogg'),
        perc = love.audio.newSource('sound/bgm4.ogg'),
    },
    volumes = {},
    metronome = {}
}

function bgm:start()
    for _,sound in pairs(self.tracks) do
        sound:setLooping(true)
        sound:setVolume(0)
        sound:play()
    end
end

function bgm:update(dt)
    for key,sound in pairs(self.tracks) do
        if self.volumes[key] then
            sound:setVolume(util.lerp(sound:getVolume(), self.volumes[key], dt))
        end
    end

    self.metronome.beat = self.tracks.bass:tell()*64/self.tracks.bass:getDuration()
    self.metronome.interval = self.tracks.bass:getDuration()/64/self.tracks.bass:getPitch()
end

function bgm:stop()
    for _,sound in pairs(self.tracks) do
        sound:setLooping(false)
    end
end

return bgm
