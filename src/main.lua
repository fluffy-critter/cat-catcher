--[[ CATcher
(c)2018 fluffy @ beesbuzz.biz
]]

setmetatable(_G, {
    __newindex = function(_, name, _)
        error("attempted to write to global variable " .. name, 2)
    end
})

local cute = require 'thirdparty.cute'
local util = require 'util'
local config = require 'config'
local profiler = config.profiler and require 'profiler'
local palette = require 'palette'
local font = love.graphics.newFont('c64-pro-mono.ttf', 8)
local bgm = require 'bgm'

local Cat = require 'Cat'
local Paddle = require 'Paddle'
local Animator = require 'Animator'
local PlatformRandomizer = require 'PlatformRandomizer'

local BoostPellet = require 'BoostPellet'

local screen = {
    scale = 1,
    x = 0,
    y = 0,
}

local paused = false
local unpauseOnFocus = false

local animator = Animator.new()

local GameDefaults = {
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
    nextLifeIncr = 500,
    levelDisplayTime = 0,
    numSaved = 0
}

local Game = {
    animator = animator,
}

local mouse = {
    x = 0,
    y = 0
}

function Game:start()
    if not Game.lives or Game.lives == 0 then
        if not Game.arena then
            Game.arena = util.shallowCopy(GameDefaults.arena)
        else
            for k,v in pairs(GameDefaults.arena) do
                Game.animator:add({
                    target = Game.arena,
                    property = k,
                    endPos = v,
                    easing = Animator.Easing.ease_inout
                })
            end
        end

        for k,v in pairs(GameDefaults) do
            if k ~= "arena" then
                Game[k] = v
            end
        end

        Game.objects = {}
        Game.effects = {}

        bgm:start()
    end
end

local function setMouseCapture(capture)
    love.mouse.setRelativeMode(capture)
    love.mouse.setVisible(false)
    love.mouse.setGrabbed(not capture)
    print(capture, love.mouse.isGrabbed())
end

function love.keypressed(key)
    if key == 'f' then
        config.fullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(config.fullscreen)
        config.save()
    elseif key == 'p' then
        paused = not paused
        setMouseCapture(not paused)
    elseif key == 'space' then
        Game:start()
    elseif key == 'escape' then
        os.exit(0)
    end
end

function love.mousepressed()
    Game:start()
end

function love.focus(focus)
    setMouseCapture(focus)
    if not focus then
        unpauseOnFocus = not paused
        paused = true
    elseif unpauseOnFocus then
        paused = false
        unpauseOnFocus = false
    end
end

function love.load(args)
    cute.go(args)

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

    Game.items = {
        BoostPellet
    }

    screen.textLayer = love.graphics.newCanvas(320, 200)
    screen.textLayer:setFilter("nearest")

    mouse.cursor = love.graphics.newImage("gfx/mouse.png")
    mouse.cursor:setFilter("nearest")

    Game:start()
end

function Game:getSpawnLocation()
    return math.random(0, self.arena.width/8 + 1)*8,
        math.random(math.floor((self.arena.launchY + self.arena.launchH)/8),
            math.floor(self.paddle.y/8) - 1)*8
end

function love.resize(w, h)
    print("resize " .. w .. ' ' .. h)
    if not config.fullscreen then
        config.width, config.height = love.window.getMode()
        config.save()
    end
end

function love.mousemoved(x, y, dx, _)
    if not paused then
        Game.paddle:impulse(dx*config.mouseSpeed/screen.scale)
    end

    mouse.x = (x - screen.x)/screen.scale
    mouse.y = (y - screen.y)/screen.scale

    if paused and (mouse.x < 0 or mouse.x >= 320 or mouse.y < 0 or mouse.y >= 200) then
        -- workaround for LÖVE bug that was causing the mouse to remain grabbed
        -- even if it's been explicitly set not-grabbed
        love.mouse.setCursor()
        love.mouse.setVisible(true)
        love.mouse.setGrabbed(false)
    else
        love.mouse.setVisible(false)
    end
end

function love.update(dt)
    if profiler then profiler.attach("update", dt) end

    animator:update(dt)

    bgm:update(dt)
    Game.metronome = bgm.metronome
    Game.levelDisplayTime = Game.levelDisplayTime - dt

    if paused then
        dt = 0
    end

    Game.spawnTime = Game.spawnTime - dt
    if Game.spawnTime <= 0 then
        if config.debug then print("spawmtime",Game.spawnTime) end
        table.insert(Game.objects, Game.items[math.random(#Game.items)].new({}, Game))
        Game.spawnTime = math.random(5, 10)
    end

    local catCount = 0
    for _,cat in ipairs(Game.cats) do
        if cat:active() then
            catCount = catCount + 1
        end
    end

    if catCount == 0 and Game.lives > 0 then
        -- reward with 100 points for every rescued cat
        print("Level " .. Game.level .. ": saved " .. Game.numSaved .. " cats")
        Game.score = Game.score + 100*Game.numSaved
        Game.numSaved = 0

        Game.level = Game.level + 1
        Game.levelDisplayTime = Game.metronome.interval*(8 - (Game.metronome.beat % 4))

        if Game.lives < 9 and Game.level % 5 == 0 then
            Game.lives = Game.lives + 1
        end

        local newCats = {}
        table.insert(newCats, Cat.new({
            color = Game.level == 1 and palette.white or nil,
            scale = 1,
            y = Game.arena.launchY,
            vx = 30 + Game.level
        }))

        for n = 2,math.min(Game.level, Game.lives) do
            local scale = math.random()*math.random()*0.25 + 0.5
            table.insert(newCats, Cat.new({
                scale = scale,
                y = Game.arena.launchY,
                vx = 30 + math.max(0, Game.level - n),
                ay = 120 + n*Game.level
            }))
        end

        -- kern the cats
        local x = 0
        for _,cat in ipairs(newCats) do
            cat.x = 0
            local ll, _, rr = cat:getBounds()
            local ofs = x - rr - 5
            cat.x = ofs
            x = ll + ofs
            table.insert(Game.cats, cat)
        end

        if Game.level > 1 then
            bgm.volumes.bass = 1
        end

        if Game.level >= 10 then
            if not Game.randomizer then
                Game.randomizer = PlatformRandomizer.new()
                table.insert(Game.effects, Game.randomizer)
            else
                Game.randomizer.timeBase = Game.randomizer.timeBase * 0.9
                Game.randomizer.timeJitter = Game.randomizer.timeJitter * 1.1
            end

            bgm.volumes.bass = (Game.lives % 2 == 0) and 1 or 0
            bgm.volumes.doot = (Game.lives % 3 == 0) and 1 or 0
            bgm.volumes.pad = (Game.lives > 5) and 1 or 0
        elseif Game.level > 5 then
            local destY = math.random(60, 100)
            animator:add({
                target = Game.arena,
                property = 'destY',
                endPos = destY,
                easing = Animator.Easing.ease_inout
            })
            animator:add({
                target = Game.arena,
                property = 'launchY',
                endPos = math.random(40, destY),
                easing = Animator.Easing.ease_inout
            })
            bgm.volumes.pad = Game.level % 2
            bgm.volumes.doot = 1 - bgm.volumes.pad
        elseif Game.level > 3 then
            animator:add({
                target = Game.arena,
                property = 'destY',
                endPos = math.random(80, 120),
                easing = Animator.Easing.ease_inout
            })
            bgm.volumes.pad = 1
        end

        bgm.volumes.perc = 1
    elseif catCount == 0 then
        bgm:stop()
    end

    util.runQueue(Game.effects, function(effect)
        return effect:update(dt, Game)
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
        Game.nextLife = Game.nextLife + Game.nextLifeIncr
        Game.nextLifeIncr = Game.nextLifeIncr + 500
    end

    if not config.highscore or Game.score > config.highscore then
        config.highscore = Game.score
        config.save()
    end

    if profiler then profiler.detach() end
end

local function printCentered(text, x, y, w)
    local scrW = math.floor(w/8)
    local txtW = text:len()
    local spaces = math.floor((scrW - txtW + 1)/2)
    love.graphics.print(text, x + 8*spaces, y)
end

function love.draw()
    if profiler then profiler.attach("draw") end

    love.graphics.clear(unpack(palette.lightblue))

    local sw, sh = love.graphics.getDimensions()
    local tw, th = 320*config.overscan, 200*config.overscan
    local scale = math.min(sw/tw, sh/th)

    screen.w, screen.h = math.floor(320*scale), math.floor(200*scale)
    screen.x, screen.y = (sw - screen.w)/2, (sh - screen.h)/2
    screen.scale = scale

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
        love.graphics.setColor(palette.red)
        love.graphics.printf('Next at ' .. Game.nextLife, 0, 9, 320, "right")

        if paused then
            love.graphics.setColor(palette.lightgreen)
            printCentered('Pawsed!', 0, 89, 320)
        end

        if Game.levelDisplayTime > 0 then
            love.graphics.setColor(palette.yellow)
            printCentered('Level ' .. Game.level, 0, 97, 320)
        elseif Game.lives == 0 then
            love.graphics.setColor(palette.cyan)
            printCentered('Game Over', 0, 97, 320)
            printCentered("High Score " .. config.highscore, 0, 105, 320)
        end
    end)

    screen.canvas:renderTo(function()
        love.graphics.clear(unpack(palette.blue))

        love.graphics.push()
        love.graphics.scale(scale)

        love.graphics.setColor(255,255,255)
        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.draw(screen.textLayer)

        love.graphics.setColor(palette.lightred)
        love.graphics.rectangle("fill", 0, Game.arena.launchY, Game.arena.launchX, Game.arena.launchH)
        love.graphics.setColor(palette.lightgreen)
        love.graphics.rectangle("fill", Game.arena.destX, Game.arena.destY,
            Game.arena.width - Game.arena.destX, Game.arena.destH)

        Game.paddle:draw()
        util.runQueue(Game.cats, function(cat)
            return cat:draw()
        end)
        util.runQueue(Game.objects, function(obj)
            return obj:draw()
        end)

        if paused then
            love.graphics.setColor(palette.white)
            love.graphics.draw(mouse.cursor, mouse.x, mouse.y, 0, 1, 1, 0, 3)
        end

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
