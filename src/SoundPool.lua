--[[ CATcher
(c)2018 fluffy at beesbuzz dot biz

sound pool functions
]]

local util = require('util')

local SoundPool = {}

function SoundPool.new(o)
    local self = o or {}

    util.applyDefaults(self, {
        sources = {}
    })

    setmetatable(self, {__index = SoundPool})
    return self
}

-- Play a sound, optionally calling a pre-play callback first
function SoundPool.play(sdata, cb)
    local sources = self.sources[sdata] or {}

    local source
    for _,s in ipairs(sources) do
        if not s:isPlaying() then
            source = s
            break
        end
    end
    if not source then
        source = love.audio.newSource(sdata)
        table.insert(sources, source)
    end

    source:rewind()
    if cb then
        cb(source)
    end
    source:play()
    return source
end

return SoundPool
