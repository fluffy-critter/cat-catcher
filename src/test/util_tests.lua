--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Utility library unit tests

]]

local cute = require 'thirdparty.cute'
local notion = cute.notion
local check = cute.check
-- local minion = cute.minion
-- local report = cute.report

local util = require 'util'

notion("Enums form an appropriate equivalence class", function()
    local myEnum = util.enum("first", "second", "third")

    check(myEnum.first.val).is(1)
    check(myEnum(1).val).is(1)

    check(myEnum.first == myEnum(1)).is(true)
    check(myEnum.first == myEnum(2)).is(false)
    check(myEnum.first == myEnum(3)).is(false)

    check(myEnum.second == myEnum(1)).is(false)
    check(myEnum.second == myEnum(2)).is(true)
    check(myEnum.second == myEnum(3)).is(false)

    check(myEnum.third == myEnum(1)).is(false)
    check(myEnum.third == myEnum(2)).is(false)
    check(myEnum.third == myEnum(3)).is(true)
end)

notion("Enums compare correctly", function()
    local myEnum = util.enum("first", "second", "third")

    check(myEnum.second < myEnum.first).is(false)
    check(myEnum.second < myEnum.second).is(false)
    check(myEnum.second < myEnum.third).is(true)

    check(myEnum.second <= myEnum.first).is(false)
    check(myEnum.second <= myEnum.second).is(true)
    check(myEnum.second <= myEnum.third).is(true)

    check(myEnum.second == myEnum.first).is(false)
    check(myEnum.second == myEnum.second).is(true)
    check(myEnum.second == myEnum.third).is(false)

    check(myEnum.second >= myEnum.first).is(true)
    check(myEnum.second >= myEnum.second).is(true)
    check(myEnum.second >= myEnum.third).is(false)

    check(myEnum.second > myEnum.first).is(true)
    check(myEnum.second > myEnum.second).is(false)
    check(myEnum.second > myEnum.third).is(false)

    check(myEnum.second ~= myEnum.first).is(true)
    check(myEnum.second ~= myEnum.second).is(false)
    check(myEnum.second ~= myEnum.third).is(true)
end)

notion("Enums don't compare across types", function()
    local e1 = util.enum("a")
    local e2 = util.enum("a")

    check(e1.a == e2.a).is(false)
    check(e1.a ~= e2.a).is(true)
end)

notion("applyDefaults works right", function()
    local defaults = { foo = 1, bar = 2 }
    local applyTo = { bar = 3, baz = 5 }
    util.applyDefaults(applyTo, defaults)

    check(applyTo.foo).is(1)
    check(applyTo.bar).is(3)
    check(applyTo.baz).is(5)
    check(applyTo.qwer).is(nil)
end)

notion("clamp", function()
    check(util.clamp(5,0,15)).is(5)
    check(util.clamp(-1,0,15)).is(0)
    check(util.clamp(100,0,15)).is(15)
end)

notion("array comparisons", function()
    check(util.arrayLT({1,2,3},{2,3,4})).is(true)
    check(util.arrayLT({1,2,3},{1,2,3})).is(false)
    check(util.arrayLT({1,2},{1,2,3})).is(true)
    -- TODO more of these
end)

notion("arrays are comparable", function()
    local a1 = util.comparable({1,2,3})
    local a2 = util.comparable({2,3,4})

    check(a1 < a1).is(false)
    check(a1 <= a1).is(true)
    check(a1 == a1).is(true)
    check(a1 >= a1).is(true)
    check(a1 > a1).is(false)
    check(a1 ~= a1).is(false)

    check(a1 < a2).is(true)
    check(a1 <= a2).is(true)
    check(a1 == a2).is(false)
    check(a1 >= a2).is(false)
    check(a1 > a2).is(false)
    check(a1 ~= a2).is(true)
end)

notion("color premultiplication", function()
    check(util.premultiply({255,255,255})).shallowMatches({255,255,255,255})
    check(util.premultiply({255,255,255,255})).shallowMatches({255,255,255,255})
    check(util.premultiply({255,0,0,127})).shallowMatches({127,0,0,127})
    check(util.premultiply({255,255,255,0})).shallowMatches({0,0,0,0})
end)

notion("quadratics", function()
    check({util.solveQuadratic(1, 0, -1)}).shallowMatches({-1,1})
    check(util.solveQuadratic(1, 0, 0)).is(0)
    check(util.solveQuadratic(1, 0, 1)).is(nil)
end)

notion("cpairs", function()
    local t1 = {1,2,3}
    local t2 = {}
    local t3 = {4}

    local concatted = {}
    for tbl,idx,val in util.cpairs(t1, t2, t3, t2) do
        table.insert(concatted, {tbl, idx, val})
    end

    check(#concatted).is(4)
    check(concatted[1]).shallowMatches({t1, 1, 1})
    check(concatted[2]).shallowMatches({t1, 2, 2})
    check(concatted[3]).shallowMatches({t1, 3, 3})
    check(concatted[4]).shallowMatches({t3, 1, 4})
end)

notion("mpairs", function()
    local t1 = {a=4, b=99, c=20}
    local t2 = {}
    local t3 = {d=16, b=5}
    local result = {}
    local count = 0

    for _,k,v in util.mpairs(t1, t2, t3) do
        count = count + 1
        result[k] = v
    end

    check(count).is(5)
    check(result.a).is(4)
    check(result.b).is(5)
    check(result.c).is(20)
    check(result.d).is(16)
end)

notion("clock", function()
    local clock = util.clock(60, {8, 4}, 1)

    notion("timeToPos", function()
        check(clock.timeToPos(1)).shallowMatches({0, 0, 0})
        check(clock.timeToPos(2)).shallowMatches({0, 0, 1})
        check(clock.timeToPos(3)).shallowMatches({0, 0, 2})
        check(clock.timeToPos(4)).shallowMatches({0, 0, 3})
        check(clock.timeToPos(5)).shallowMatches({0, 1, 0})
    end)

    notion("posToTime", function()
        check(clock.posToTime({0})).is(1)
        check(clock.posToTime({0,1})).is(5)
        check(clock.posToTime({1,0})).is(33)

        check(clock.posToTime({0,0,-1})).is(0)
    end)

    notion("posToDelta", function()
        check(clock.posToDelta({0})).is(0)
        check(clock.posToDelta({1})).is(32)
    end)

    notion("offsets", function()
        local time = 17
        local base = clock.timeToPos(time)
        check(clock.posToTime({base[1], base[2], base[3] + 1})).is(time + 1)
        check(clock.posToTime({base[1], base[2], base[3] + 4})).is(time + 4)
        check(clock.posToTime({base[1], base[2] + 1, base[3]})).is(time + 4)
        check(clock.posToTime({base[1] + 1, base[2], base[3]})).is(time + 32)
    end)

    notion("offset modulus", function()
        check(clock.timeToPos(clock.posToTime({0,0,4}))).shallowMatches({0,1,0})
        check(clock.timeToPos(clock.posToTime({0,8,0}))).shallowMatches({1,0,0})
        check(clock.timeToPos(clock.posToTime({0,1,-1}))).shallowMatches({0,0,3})
    end)

    notion("normalize", function()
        check(clock.normalize({0,0,0})).shallowMatches({0,0,0})
        check(clock.normalize({0,0,4})).shallowMatches({0,1,0})
        check(clock.normalize({0,8,0})).shallowMatches({1,0,0})
        check(clock.normalize({0,8,-1})).shallowMatches({0,7,3})
        check(clock.normalize({1,0,-1})).shallowMatches({0,7,3})
    end)

    notion("addOffset", function()
        check(clock.addOffset({1}, {0,0,1})).shallowMatches({1,0,1})
        check(clock.addOffset({1}, {0,0,-1})).shallowMatches({0,7,3})
    end)

    notion("iteration", function()
        local posArr = {}
        for t in clock.iterator({1,3,-4}, {1,5,1}, {0,0,2}) do
            table.insert(posArr, t)
        end

        check(#posArr).is(7)
        check(posArr[1]).shallowMatches({1,2,0})
        check(posArr[2]).shallowMatches({1,2,2})
        check(posArr[3]).shallowMatches({1,3,0})
        check(posArr[4]).shallowMatches({1,3,2})
        check(posArr[5]).shallowMatches({1,4,0})
        check(posArr[6]).shallowMatches({1,4,2})
        check(posArr[7]).shallowMatches({1,5,0})
    end)
end)

notion("runQueue", function()
    local queue = {}

    for i=1,10 do
        table.insert(queue, i)
    end

    util.runQueue(queue, function(item)
        return item % 2 == 0
    end)

    check(#queue).is(5)
    for _,item in ipairs(queue) do
        check(item % 2 == 1)
    end

end)
