--[[ CATcher
(c)2018 fluffy @ beesbuzz.biz

items sprites
]]

local items = {}

local imagePool = require('imagepool')
local quadtastic = require('thirdparty.libquadtastic')

local function ingest(imageFile, quadFile)
    local image = imagePool.load(imageFile, {nearest=true})
    local quads = quadtastic.create_quads(love.filesystem.load(quadFile)(),
        image:getWidth(), image:getHeight())

    for name,quad in pairs(quads) do
        items[name] = {
            sprite = image,
            quad = quad
        }
    end
end

ingest('gfx/items.png', 'gfx/items.lua')

return items