--[[ CATcher
(c)2018 fluffy at beesbuzz dot biz

Cats!
]]

local util = require('util')
local imagepool = require('imagepool')
local palette = require('palette')
local config = require('config')
local geom = require('geom')

local Cat = {}

Cat.State = util.enum("ready", "playing", "saved", "lost")
Cat.Colors = {palette.white, palette.lightblue, palette.lightred, palette.yellow, palette.gray3}

function Cat.new(o)
    local self = o or {}
    setmetatable(self, {__index=Cat})

    util.applyDefaults(self, {
        sprite = imagepool.load('gfx/cat.png', {nearest=true}),
        state = Cat.State.ready,
        color = Cat.Colors[math.random(#Cat.Colors)],
        scale = math.random(3)*0.5,
        angle = 0,
        cx = 8,
        cy = 21,
        hitF = 10,
        hitH = 11,
        hitB = 8,
        vx = 0,
        vy = 0,
        ax = 0,
        ay = 120,
        age = 0,
        dir = 1,
        points = 1,
        jump = 8,
        ofsY = 0,
        bounce = 0.98
    })

    return self
end

function Cat:getBounds()
    local xl, xr
    if self.dir < 0 then
        xl = self.hitF
        xr = self.hitB
    else
        xl = self.hitB
        xr = self.hitF
    end

    return self.x - xl*self.scale,
        self.y - self.hitH*self.scale,
        self.x + xr*self.scale,
        self.y
end

function Cat:active()
    return self.state == Cat.State.ready or self.state == Cat.State.playing
end

function Cat:collidesWith(x, y, w, h)
    local cl, ct, cr, cb = self:getBounds()
    local pl, pt, pr, pb = geom.xywh2ltrb(x,y,w,h)

    return geom.spanOverlap(cl,cr,pl,pr) and geom.spanOverlap(ct,cb,pt,pb)
end

function Cat:update(dt, game)
    if self.state == Cat.State.ready or self.state == Cat.State.saved then
        -- Kittycat dance
        local phase = game.metronome.beat + 0.25
        local ramp = util.smoothStep(math.min((phase % 1)*2, 1))
        local bounce = ramp*(1 - ramp)*4

        local ta = ((math.floor(phase + 1) % 2)*2 - 1)*0.4
        self.angle = util.lerp(-ta, ta, ramp/2)
        self.ofsY = self.jump*bounce
        self.x = self.x + bounce*dt*self.vx

        if self.state == Cat.State.ready then
            self.y = game.arena.launchY
        elseif self.state == Cat.State.saved then
            self.y = game.arena.destY
        end

        local ll = self:getBounds()
        if self.state == Cat.State.ready and ll > game.arena.launchX then
            self.y = self.y - self.ofsY
            self.ofsY = 0
            self.state = Cat.State.playing
        elseif self.state == Cat.State.saved and ll > game.arena.width then
            print("byeeee!")
            return true
        end
    elseif self.state == Cat.State.playing then
        local _, pt, pr, pb = self:getBounds()

        self.x = self.x + (self.vx + 0.5*self.ax*dt)*dt
        self.y = self.y + (self.vy + 0.5*self.ay*dt)*dt

        self.vx = self.vx + self.ax*dt
        self.vy = self.vy + self.ay*dt

        self.angle = 0 -- TODO

        -- if it hits the floor, it loses
        if self.y >= game.arena.height then
            self.vy = 0
            self.state = Cat.State.lost
            self.y = game.arena.height
            self.vx = math.min(-30, -math.abs(self.vx))
            game.lives = math.max(0, game.lives - 1)

        end

        local ll, tt, rr, _ = self:getBounds()

        -- collect powerups!
        util.runQueue(game.objects, function(obj)
            if self:collidesWith(obj.x, obj.y, obj.w, obj.h) then
                obj:onCollect(self)
                return true
            end
        end)

        -- if it hits the walls, it bounces
        if ll < 0 then
            self.x = self.x + ll
            self.vx = math.abs(self.vx)
        end
        if rr > game.arena.width then
            self.x = self.x - rr + game.arena.width
            self.vx = -math.abs(self.vx)
        end

        -- if it hits the paddle, it bounces
        if self:collidesWith(game.paddle.x, game.paddle.y, game.paddle.w, game.paddle.h) then
            if geom.spanOverlap(pt,pb,game.paddle.y,game.paddle.y+game.paddle.h) then
                -- we bounced off the side
                if pr < game.paddle.x then
                    self.vx = -math.abs(self.vx)
                    self.x = self.x - rr + game.paddle.x
                else
                    self.vx = math.abs(self.vx)
                    self.x = self.x + ll - game.paddle.w - game.paddle.x
                end
            elseif self.vy > 0 then
                -- we bounced off the top
                self.y = game.paddle.y
                self.vy = -math.abs(self.vy)*self.bounce
                self.vx = self.vx + game.paddle.vx

                game.score = game.score + self.points
                self.points = self.points + 1
            end
        end

        -- right platform
        if self:collidesWith(game.arena.destX, game.arena.destY,
            game.arena.width - game.arena.destX, game.arena.destH) then
            if pr < game.arena.destX and geom.spanOverlap(pt,pb,game.arena.destY,game.arena.destY+game.arena.destH) then
                -- bounced off the side
                print("bonk! dest")
                self.x = self.x - rr + game.arena.destX
                self.vx = -math.abs(self.vx)
            elseif self.vy < 0 then
                -- we hit our head :(
                print("ouch! dest")
                self.y = self.y + (game.arena.destY + game.arena.destH - tt)
                self.vy = math.abs(self.vy)
            else
                -- we landed! we are free!
                self.vx = math.max(30, self.vx)
                self.y = game.arena.destY
                self.state = Cat.State.saved
                game.score = game.score + 10*self.points + 100
            end
        end
    elseif self.state == Cat.State.lost then
        self.angle = math.sin(game.metronome.beat*math.pi)*.1
        self.x = self.x + self.vx*dt

        if self.x + self.cx*self.scale < 0 then
            print("byeeee :(")
            return true
        end
    end

    if self.vx > 0 then
        self.dir = 1
    elseif self.vx < 0 then
        self.dir = -1
    end
end

function Cat:draw()
    love.graphics.setColor(unpack(self.color))
    love.graphics.setBlendMode("alpha", "alphamultiply")
    love.graphics.draw(self.sprite, self.x, self.y - self.ofsY*self.scale,
        self.angle, self.scale*self.dir, self.scale, self.cx, self.cy)

    if config.debug then
        local x, y, w, h = self:getBounds()
        w = w - x
        h = h - y
        love.graphics.rectangle("line", x, y, w, h)
    end
end

return Cat
