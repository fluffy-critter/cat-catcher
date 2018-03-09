--[[CATcher
(c)2018 fluffy at beesbuzz dot biz

geometry functions
]]

local geom = {}

function geom.xywh2ltrb(x,y,w,h)
    return x,y,x+w,y+h
end

function geom.ltrb2xywh(l,t,r,b)
    return l,t,r-l,b-t
end

function geom.spanOverlap(a1, a2, b1, b2)
    return a1 < b2 and a2 > b1
end

return geom
