local cute = {}
local version = "0.1.0"
local padding = 16
local margin = 8
local show = true
local enabled = false
local hideKey = "h"
local downKey = "j"
local upKey = "k"
local offset = 0
local foundFailingTest = false
local testLocation = "test"

local tests = {}
local focusTests = {}

local stringEnds = function(s, _end)
   return _end == '' or string.sub(s,-string.len(_end)) == _end
end

-- forward declaration
local getAllFiles

getAllFiles = function(folder, allFiles)
  allFiles = allFiles or {}
  local lfs = love.filesystem
  local filesTable = lfs.getDirectoryItems(folder)
  for _,v in ipairs(filesTable) do
    local file = folder .. "/" .. v
    if lfs.isFile(file) then
      table.insert(allFiles, file)
    elseif lfs.isDirectory(file) then
      getAllFiles(file, allFiles)
    end
  end
  return allFiles
end

local addTests = function (files)
  for _, f in ipairs(files) do
    if stringEnds(f, "_tests.lua") then
      local chunk = love.filesystem.load(f)
      chunk()
    end
  end
end

local discover = function()
  local files = getAllFiles(testLocation)
  addTests(files)
end

local getTests = function ()
  local testsToRun
  if #focusTests > 0 then
    testsToRun = focusTests
  else
    testsToRun = tests
  end
  return testsToRun
end

local minions = {}

function cute.minion(name, tbl, k)
  print("creating minion...")
  print(k)
  local minion = {
    table=tbl,
    key=k,
    callback = tbl[k],
    calls = 0,
    args = {}
  }
  minions[name] = minion
  tbl[k] =  function (...)
    local arguments = {...}
    minion.calls = minion.calls + 1
    table.insert(minions[name].args, arguments)
    return minion.callback(...)
  end
end

function cute.report(name)
  return minions[name]
end

local function resetMinions()
  for name, minion in pairs(minions) do
    print("reseting minion: " .. name)
    minion.table[minion.key] = minion.callback
  end
  minions = {}
end

local runAllTests = function (headlessMode)
  print("running tests...")
  for _, test in ipairs(getTests()) do
    print(test.title)
    local passed, errorMsg = pcall(test.run)
    resetMinions()
    if (not passed) then
      foundFailingTest = true
      test.errorMsg = errorMsg
      if headlessMode then
        print("Test Failed! " .. tostring(errorMsg))
        os.exit(-1)
      end
    else
      test.passed = true
    end
  end

  if headlessMode then os.exit(0) end
end

-- controls

function cute.keypressed(key)
  if not enabled then return end

  if key == hideKey then show = not show end

  if show then
    if (key == downKey and offset < #getTests()) then offset = offset + 1 end
    if (key == upKey and offset > 0) then offset = offset - 1 end
  end
end

-- drawing functions

local _setColour = function (colour, g)
  local colours = {
    green = {122,158,53},
    black = {45,45,45},
    red = {170, 57, 57},
    lightGrey = {238,238,238, 200}
  }

  g.setColor(unpack(colours[colour]))
end

local _drawResultsBox = function(g, w, h)
  _setColour('lightGrey', g)
  g.rectangle('fill', padding, padding, w - padding*2, h - padding*2)

  if foundFailingTest then
    _setColour('red', g)
  else
    _setColour('green', g)
  end
  g.rectangle('fill', padding, padding, w - padding*2, padding)
  _setColour('black', g)
  g.printf('Cute ' .. version .. "- [h] hide [j] scroll up [k] scroll down",
    padding,
    padding + 1,
    w - padding*2,
    'center')
end

local _drawLine = function(g, i, ofs, test)
  local msg
  if test.focused then
    msg = "FOCUSED "
  else
    msg = ""
  end
  if test.passed then
    _setColour("black", g)
    msg = msg .. "Passed: " .. test.title
  else
    _setColour("red", g)
    msg = msg .. "Failed: " .. test.title .. " - " .. tostring(test.errorMsg)
  end
  g.print(msg, padding + margin, (padding * 1.5) + margin * 2 + (i - 1 - ofs)*14)
end

local _drawResults = function(g)
  for i, test in ipairs(getTests()) do
    if offset == #getTests() then break end
    if i > offset then
      _drawLine(g, i, offset, test)
    end
  end
end

local display = function (g)
  if not show then return end
  if not enabled then return end

  local w = g.getWidth()
  local h = g.getHeight()

  g.push('all')
  _drawResultsBox(g, w, h)
  _drawResults(g)
  g.pop()
end

-- Testing functions

function cute.notion(title, testMethod)
  table.insert(tests, {
    title=title,
    run=testMethod
  })
end

function cute.f_notion(title, testMethod)
  table.insert(focusTests, {
    title=title,
    run=testMethod,
    focused=true
  })
end

function cute.x_notion()
  -- do nothing
end

local _is = function (testVal, refVal)
  if type(testVal) == "table" or type(refVal) == "table" then
    error("Can't compare tables with .is, try .shallowMatches",3)
  end
  if testVal ~= refVal then error(
    tostring(testVal) .. " ~= " .. tostring(refVal), 3) end
  return true
end

local _shallowMatches = function (testTable, refTable)
  if #testTable ~= #refTable then
    local t1 = "t1: "
    local t2 = "t2: "
    for _, o in ipairs(testTable) do
      t1 = t1 .. tostring(o) .. " "
    end
    for _, o in ipairs(refTable) do
      t2 = t2 .. tostring(o) .. " "
    end
    error("Tables are different sizes: " .. t1 .. " | " .. "t2", 3)
  end

  for k, item in pairs(testTable) do
    if item ~= refTable[k] then
      error("Mismatch for element with key " .. tostring(k) ..
            ": " .. tostring(item) .. " ~= " ..
            tostring(refTable[k]), 3)
    end
  end

  return true
end

function cute.check(testVal)
  return {
    is = function (refVal) _is(testVal, refVal) end,
    shallowMatches = function (refTable) _shallowMatches(testVal, refTable) end
  }
end

-- options and running

function cute.go(args)
  local shouldGo = false
  local headless = false
  for _, arg in ipairs(args) do
    if arg == "--cute" then
      shouldGo = true
    end
    if arg == "--cute-headless" then
      shouldGo = true
      headless = true
    end
  end

  if shouldGo then
    enabled = true
    discover()
    runAllTests(headless)
  end
end

function cute.draw() display(love.graphics) end
function cute.setKeys(hide, down, up)
  hideKey = hide
  downKey = down
  upKey = up
end

return cute
