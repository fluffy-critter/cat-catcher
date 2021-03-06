--[[ CATcher
(c)2018 fluffy at beesbuzz dot biz

Color palette
]]

local palette = {
    {0,0,0},        -- 1 black
    {255,255,255},  -- 2 white
    {104,55,43},    -- 3 red
    {112,164,178},  -- 4 cyan
    {111,61,134},   -- 5 violet
    {88,141,67},    -- 6 green
    {53,40,121},    -- 7 blue
    {184,199,111},  -- 8 yellow
    {111,79,37},    -- 9 orange
    {67,57,0},      -- 10 brown
    {154,103,89},   -- 11 lightred
    {68,68,68},     -- 12 gray1
    {108,108,108},  -- 13 gray2
    {154,210,132},  -- 14 lightgreen
    {108,94,181},   -- 15 lightblue
    {149,149,149}   -- 16 gray3
}

for key,val in ipairs(palette) do
    palette[key] = {val[1]/255, val[2]/255, val[3]/255}
end

for idx,name in ipairs({
    "black", "white", "red", "cyan", "violet", "green", "blue", "yellow",
    "orange", "brown", "lightred", "gray1", "gray2", "lightgreen", "lightblue", "gray3"
}) do
    palette[name] = palette[idx]
end

return palette
