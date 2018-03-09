--[[ CATcher
(c)2018 fluffy @ beesbuzz.biz
]]

setmetatable(_G, {
    __newindex = function(_, name, _)
        error("attempted to write to global variable " .. name, 2)
    end
})

local cute = require('thirdparty.cute')
local util = require('util')
local config = require('config')
local profiler = config.profiler and require('profiler')
local palette = require('palette')

local Cat = require('Cat')
local Paddle = require('Paddle')

local BoostPellet = require('BoostPellet')

local screen = {
    scale = 1,
    ox = 0,
    oy = 0
}

local Game = {
    arena = {
        launchX = 32,
        launchY = 24,
        launchH = 4,
        destX = 320 - 32,
        destY = 100,
        destH = 8,
        width = 320,
        height = 200
    },
    spawnTime = 10
}

function love.keypressed(key)
    if key == 'f' then
        config.fullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(config.fullscreen)
        config.save()
    end
end

function love.load(args)
    cute.go(args)

    love.mouse.setRelativeMode(true)

    Game.bgm = {
        love.audio.newSource('sound/bgm1.ogg'),
        -- love.audio.newSource('sound/bgm2.ogg'),
        -- love.audio.newSource('sound/bgm3.ogg'),
        love.audio.newSource('sound/bgm4.ogg'),
    }

    for _,music in ipairs(Game.bgm) do
        music:setLooping(true)
        music:setVolume(0.1)
        music:play()
    end

    love.window.setMode(config.width, config.height, {
        resizable = true,
        fullscreen = config.fullscreen,
        vsync = config.vsync,
        highdpi = config.highdpi,
        minwidth = 480,
        minheight = 480
    })

    Game.cats = {}
    table.insert(Game.cats, Cat.new({
        x = -20,
        y = 24,
        vx = 30,
        state = Cat.State.ready,
        scale = 1
    }))

    Game.paddle = Paddle.new()

    Game.metronome = {}

    Game.objects = {}
    Game.items = {
        BoostPellet
    }
end

function Game:getSpawnLocation()
    return math.random(0, self.arena.width/8 + 1)*8,
        math.random(math.floor((self.arena.launchY + self.arena.launchH)/8),
            math.floor(self.paddle.y/8) - 1)*8
end

local time = 0
local speed = 1

local function setSpeed(s)
    speed = s
    for _,music in ipairs(Game.bgm) do
        music:setPitch(speed)
    end
end

function love.resize(w, h)
    print("resize " .. w .. ' ' .. h)
    if not config.fullscreen then
        config.width, config.height = love.window.getMode()
        config.save()
    end
end

function love.mousemoved(_, _, dx, _)
    Game.paddle:impulse(dx/screen.scale)
end

function love.update(dt)
    if profiler then profiler.attach("update", dt) end

    time = time + dt
    setSpeed(math.sin(time*.1)*0 + 1)

    Game.spawnTime = Game.spawnTime - dt*speed
    if Game.spawnTime <= 0 then
        print("spawmtime",Game.spawnTime)
        table.insert(Game.objects, Game.items[math.random(#Game.items)].new({}, Game))
        Game.spawnTime = math.random(5, 10)
    end

    Game.metronome.beat = Game.bgm[1]:tell()*64/Game.bgm[1]:getDuration()
    Game.metronome.interval = Game.bgm[1]:getDuration()/64/speed

    Game.paddle:update(dt)
    util.runQueue(Game.cats, function(cat)
        return cat:update(dt, Game)
    end)

    util.runQueue(Game.objects, function(obj)
        return obj:update(dt, Game)
    end)

    if profiler then profiler.detach() end
end

function love.draw()
    if profiler then profiler.attach("draw") end

    love.graphics.clear(unpack(palette.lightblue))

    local sw, sh = love.graphics.getDimensions()
    local tw, th = 320*config.overscan, 200*config.overscan
    local scale = math.min(sw/tw, sh/th)

    screen.w, screen.h = math.floor(320*scale), math.floor(200*scale)
    screen.x, screen.y = (sw - screen.w)/2, (sh - screen.h)/2

    if not screen.canvas or screen.canvas:getWidth() ~= screen.w or screen.canvas:getHeight() ~= screen.h then
        screen.canvas = love.graphics.newCanvas(screen.w, screen.h)
    end

    screen.canvas:renderTo(function()
        love.graphics.clear(unpack(palette.blue))

        love.graphics.push()
        love.graphics.scale(scale)

        love.graphics.setColor(unpack(palette.lightred))
        love.graphics.rectangle("fill", 0, Game.arena.launchY, Game.arena.launchX, Game.arena.launchH)
        love.graphics.setColor(unpack(palette.lightgreen))
        love.graphics.rectangle("fill", Game.arena.destX, Game.arena.destY,
            Game.arena.width - Game.arena.destX, Game.arena.destH)

        Game.paddle:draw()
        util.runQueue(Game.cats, function(cat)
            return cat:draw()
        end)
        util.runQueue(Game.objects, function(obj)
            return obj:draw()
        end)

        love.graphics.pop()
    end)

    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.setColor(255,255,255)
    love.graphics.draw(screen.canvas, screen.x, screen.y)

    if profiler then
        profiler.detach()
        profiler.draw()
        profiler.attach("after")
    end
end
