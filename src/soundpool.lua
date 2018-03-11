--[[ CATcher
(c)2018 fluffy at beesbuzz dot biz

sound pool functions
]]

local soundpool = {}

local datas = {}
local sources = {}

function soundpool.load(path)
    if not datas[path] then
        datas[path] = love.sound.newSoundData(path)
    end
    return datas[path]
end

-- Play a sound, optionally calling a pre-play callback first
function soundpool.play(sdata, cb)
    if not sources[sdata] then
        sources[sdata] = {}
    end
    local spool = sources[sdata]

    local source
    for _,s in ipairs(spool) do
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

return soundpool
