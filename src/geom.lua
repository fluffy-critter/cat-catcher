--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local geom = {}

geom.collision_stats = {}

local function cs_incr(key)
    geom.collision_stats[key] = (geom.collision_stats[key] or 0) + 1
end

-- Check if two rectangles overlap (note: x2 must be >= x1, same for y)
function geom.quadsOverlap(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
    return (
        (ax1 < bx2) and
        (bx1 < ax2) and
        (ay1 < by2) and
        (by1 < ay2))
end

--[[ Find the distance between the point x0,y0 and the projection of the line segment x1,y1 -- x2,y2, with
sign based on winding.

Outside (positive) is considered to the left of the line (i.e. clockwise winding)
]]
function geom.linePointDistance(x0, y0, x1, y1, x2, y2)
    -- adapted from https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line#Line_defined_by_two_points
    local dx = x2 - x1
    local dy = y2 - y1
    return (dy*x0 - dx*y0 + x2*y1 - y2*x1)/math.sqrt(dx*dx + dy*dy)
end

-- Project a point onto the line segment, and return where it is relative to x1,y1=0 x2,x2=1
function geom.projectPointToLine(x, y, x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1

    local xo = x - x1
    local yo = y - y1

    return (xo*dx + yo*dy)/(dx*dx + dy*dy)
end

-- Get the perpendicular line - NOT NORMALIZED
function geom.getNormal(x1, y1, x2, y2)
    return { y2 - y1, x1 - x2 }
end

-- Normalize a vector to a particular length
function geom.normalize(nrm, len)
    len = len or 1

    local x, y = unpack(nrm)
    local d = math.sqrt(x*x + y*y)
    return {x*len/d, y*len/d}
end

-- get the AABB of a polygon; {x0, y0, x1, y1}
function geom.getAABB(poly)
    cs_incr('get_aabb')

    local aabb = {poly[1], poly[2], poly[1], poly[2]}

    for i = 3, #poly, 2 do
        aabb[1] = math.min(aabb[1], poly[i])
        aabb[2] = math.min(aabb[2], poly[i + 1])
        aabb[3] = math.max(aabb[3], poly[i])
        aabb[4] = math.max(aabb[4], poly[i + 1])
    end

    return aabb
end

-- check to see if a ball collides with an AABB
function geom.pointAABBCollision(x, y, r, aabb)
    cs_incr('point_aabb_test')
    if x + r <= aabb[1] or y + r <= aabb[2] or x - r >= aabb[3] or y - r >= aabb[4] then
        cs_incr('point_aabb_fail')
        return false
    end
    cs_incr('point_aabb_pass')
    return true
end

-- check to see if two balls collide; returns false, or displacement normal for ball 1 as {x,y}
function geom.pointPointCollision(x1, y1, r1, x2, y2, r2)
    local dx = x1 - x2
    local dy = y1 - y2
    local len = math.sqrt(dx*dx + dy*dy)
    local limit = r1 + r2
    if len < limit then
        local disp = limit - len
        return geom.normalize({dx*disp/len, dy*disp/len})
    end
    return false
end

--[[ check to see if a ball collides with a polygon (clockwise winding); returns false if it's not collided,
displacement vector as {x,y} if it is
]]
function geom.pointPolyCollision(x, y, r, poly)
    cs_incr('point_poly_test')

    local npoints = #poly / 2

    local x1, y1, x2, y2
    x2 = poly[npoints*2 - 1]
    y2 = poly[npoints*2]

    local maxSide
    local maxSideDist
    local maxSideNormal
    local maxSideProj

    for i = 1, npoints do
        x1 = x2
        y1 = y2
        x2 = poly[i*2 - 1]
        y2 = poly[i*2]

        local dist = geom.linePointDistance(x, y, x1, y1, x2, y2)

        if dist >= r then
            -- We are fully outside on this side, so we are outside
            cs_incr('point_poly_face_inclusion_fail')
            return false
        end

        -- find the closest side
        if not maxSide or dist > maxSideDist then
            maxSide = i
            maxSideDist = dist
            maxSideNormal = geom.getNormal(x1, y1, x2, y2)
            maxSideProj = geom.projectPointToLine(x, y, x1, y1, x2, y2)
        end
    end

    -- is our center inside the nearest segment? If so, we just use its normal
    if maxSideProj >= 0 and maxSideProj <= 1 then
        cs_incr('point_poly_face_projection_pass')
        return geom.normalize(maxSideNormal, r - maxSideDist)
    end

    --[[ we are using the nearest corner instead; fortunately in this case the center of the circle is
    going to be outside the poly ]]
    local cornerX, cornerY
    local cornerDist2
    for i = 1, npoints do
        local cx = x - poly[i*2 - 1]
        local cy = y - poly[i*2]
        local cd = cx*cx + cy*cy
        if not cornerDist2 or cd < cornerDist2 then
            cornerDist2 = cd
            cornerX = cx
            cornerY = cy
        end
    end

    if cornerDist2 >= r*r then
        -- oops, after all that work it turns out we're not actually intersecting
        cs_incr('point_poly_corner_fail')
        return false
    end

    cs_incr('point_poly_corner_pass')
    return geom.normalize({cornerX, cornerY}, r - math.sqrt(cornerDist2))
end

-- Generate a random vector of a given length (default=1)
function geom.randomVector(length)
    local vx = math.random() - 0.5
    local vy = math.random() - 0.5
    return geom.normalize({vx, vy}, length)
end

function geom.vectorLength(vector)
    local vx, vy = unpack(vector)
    return math.sqrt(vx*vx + vy*vy)
end

-- Reflect a vector (vx,vy) per a surface normal
function geom.reflectVector(nrm, vx, vy)
    local nx, ny = unpack(nrm)

    -- calculate the perpendicular projection of our reversed velocity vector onto the reflection normal
    local mag2 = nx*nx + ny*ny
    local dot = nx*vx + ny*vy
    local px = -nx*dot/mag2
    local py = -ny*dot/mag2

    return px, py
end


return geom
