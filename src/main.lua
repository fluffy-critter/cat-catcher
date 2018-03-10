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
local font = love.graphics.newFont('c64-pro-mono.ttf', 8)

local Cat = require('Cat')
local Paddle = require('Paddle')

local BoostPellet = require('BoostPellet')

local screen = {
    scale = 1,
    ox = 0,
    oy = 0,
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
    spawnTime = 10,
    lives = 9,
    score = 0,
    level = 0,
    nextLife = 1000,
    levelDisplayTime = 0
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
        -- music:setVolume(0.1)
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
    Game.paddle = Paddle.new()

    Game.metronome = {}

    Game.objects = {}
    Game.items = {
        BoostPellet
    }

    Game.effects = {}

    screen.textLayer = love.graphics.newCanvas(320, 200)
    screen.textLayer:setFilter("nearest")
end

function Game:getSpawnLocation()
    return math.random(0, self.arena.width/8 + 1)*8,
        math.random(math.floor((self.arena.launchY + self.arena.launchH)/8),
            math.floor(self.paddle.y/8) - 1)*8
end

local function setSpeed(speed)
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

    Game.metronome.beat = Game.bgm[1]:tell()*64/Game.bgm[1]:getDuration()
    Game.metronome.interval = Game.bgm[1]:getDuration()/64/Game.bgm[1]:getPitch()

    Game.levelDisplayTime = Game.levelDisplayTime - dt

    Game.spawnTime = Game.spawnTime - dt
    if Game.spawnTime <= 0 then
        print("spawmtime",Game.spawnTime)
        table.insert(Game.objects, Game.items[math.random(#Game.items)].new({}, Game))
        Game.spawnTime = math.random(5, 10)
    end

    if #Game.cats == 0 and Game.lives > 0 then
        Game.level = Game.level + 1
        Game.levelDisplayTime = Game.metronome.interval*(8 - (Game.metronome.beat % 4))

        if Game.lives < 9 then
            Game.lives = Game.lives + 1
        end

        table.insert(Game.cats, Cat.new({
            color = Game.level == 1 and palette.white or nil,
            scale = 1,
            x = -20,
            y = 24,
            vx = 30 + Game.level,
        }))

        for i = 2,math.min(Game.level, Game.lives) do
            table.insert(Game.cats, Cat.new({
                scale = 0.5,
                x = -10 - 14*i,
                y = 24,
                vx = 30 + Game.level
            }))
        end
    end

    util.runQueue(Game.effects, function(effect)
        return effect:update(dt)
    end)

    Game.paddle:update(dt)
    util.runQueue(Game.cats, function(cat)
        return cat:update(dt, Game)
    end)

    util.runQueue(Game.objects, function(obj)
        return obj:update(dt, Game)
    end)

    if Game.score >= Game.nextLife then
        Game.lives = Game.lives + 1
        Game.nextLife = Game.nextLife + 1000
    end

    if not config.highscore or Game.score > config.highscore then
        config.highscore = Game.score
        config.save()
    end

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

    screen.textLayer:renderTo(function()
        love.graphics.clear(0,0,0,0)

        love.graphics.setBlendMode("alpha", "alphamultiply")

        if config.debug then
            love.graphics.setColor(palette.black)
            for x = 0,320,8 do
                love.graphics.line(x, 0, x, 200)
            end
            for y = 0,200,8 do
                love.graphics.line(0, y, 320, y)
            end
        end

        love.graphics.setFont(font)
        love.graphics.setColor(palette.white)
        love.graphics.print('Score: ' .. Game.score, 0, 1)
        love.graphics.setColor(palette.lightred)
        love.graphics.printf('Lives: ' .. Game.lives, 0, 1, 320, "right")

        if Game.levelDisplayTime > 0 then
            love.graphics.setColor(palette.yellow)
            love.graphics.printf('Level ' .. Game.level, 0, 101, 320, "center")
        elseif Game.lives == 0 then
            love.graphics.setColor(palette.cyan)
            love.graphics.printf('Game Over', 0, 101, 320, "center")
            love.graphics.printf("High Score: " .. config.highscore, 0, 109, 320, "center")
        end
    end)

    screen.canvas:renderTo(function()
        love.graphics.clear(unpack(palette.blue))

        love.graphics.push()
        love.graphics.scale(scale)

        love.graphics.setColor(255,255,255)
        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.draw(screen.textLayer)

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
