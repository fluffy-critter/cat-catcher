--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Utility library unit tests

]]

local cute = require('thirdparty.cute')
local notion = cute.notion
local check = cute.check

local geom = require('geom')

notion("projectPointToLine", function()
    check(geom.projectPointToLine(0, 100, 0, 0, 100, 0)).is(0)
    check(geom.projectPointToLine(50, 100, 0, 0, 100, 0)).is(0.5)
    check(geom.projectPointToLine(100, 100, 0, 0, 100, 0)).is(1)

    check(geom.projectPointToLine(100, 0, 0, 0, 0, 100)).is(0)
    check(geom.projectPointToLine(100, 50, 0, 0, 0, 100)).is(0.5)
    check(geom.projectPointToLine(100, 100, 0, 0, 0, 100)).is(1)

    check(geom.projectPointToLine(0, 0, 0, 0, 100, 100)).is(0)
    check(geom.projectPointToLine(50, 50, 0, 0, 100, 100)).is(0.5)
    check(geom.projectPointToLine(100, 100, 0, 0, 100, 100)).is(1)
end)

notion("pointPolyCollision", function()
    local poly = {0, 0, 100, 0, 100, 100, 0, 100}

    -- outside
    check(geom.pointPolyCollision(-100, -100, 5, poly)).is(false)

    -- center of each face
    check(geom.pointPolyCollision(0, 50, 5, poly)).shallowMatches({-5,0})
    check(geom.pointPolyCollision(50, 0, 5, poly)).shallowMatches({0,-5})
    check(geom.pointPolyCollision(100, 50, 5, poly)).shallowMatches({5,0})
    check(geom.pointPolyCollision(50, 100, 5, poly)).shallowMatches({0,5})

    -- corners
    local ofs = math.sqrt(2) - 1
    local function epsilon(nrm)
        return {math.floor(nrm[1]*10000 + 0.5), math.floor(nrm[2]*10000 + 0.5)}
    end
    check(epsilon(geom.pointPolyCollision(-1, -1, 2, poly))).shallowMatches(epsilon({-ofs,-ofs}))
    check(epsilon(geom.pointPolyCollision(101, -1, 2, poly))).shallowMatches(epsilon({ofs,-ofs}))
    check(epsilon(geom.pointPolyCollision(-1, 101, 2, poly))).shallowMatches(epsilon({-ofs,ofs}))
    check(epsilon(geom.pointPolyCollision(101, 101, 2, poly))).shallowMatches(epsilon({ofs,ofs}))

    -- large circle on small poly
    check(geom.pointPolyCollision(-4999, 50, 5000, poly)).shallowMatches({-1,0})
end)
