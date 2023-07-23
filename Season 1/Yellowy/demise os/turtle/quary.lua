local config = require "config"

local function clear()
  term.clear()
  term.setCursorPos(1, 1)
end

clear()

local fuelLevel = turtle.getFuelLevel()
local startLoc = { gps.locate() }
local startY = startLoc[2]
local current = startLoc

local blocksMined = 0
local zToGo = 0

local facing = 'south'
local currentTool = 'pickaxe'

-- rednet=
local rednetChannel = config.computerId
peripheral.find('modem', rednet.open)
local percent = '0'

clear()

-- Configuration
print('Remember that the chunks have to be loaded')
term.setCursorPos(1, 2)
print('-> x')
local sizeX = tonumber(read())
term.setCursorPos(1, 3)
print('-> z')
local sizeZ = tonumber(read())
term.setCursorPos(1, 4)
print('-> y')
local toYLevel = tonumber(read())

clear()

-- Start of functions (Don't edit these unless you know what you are doing)
local function equals(a, b) -- this function sucks ass, there has to be a better way to do this but it probably won't change
  if a[1] == b[1] then
    if a[2] == b[2] then
      if a[3] == b[3] then
        return true
      end
      return false
    end
    return false
  end
  return false
end

local function face(direction)
  if facing == direction then
    facing = direction
  end
  if facing == 'north' and direction == 'east' then
    turtle.turnRight()
    facing = direction
  end
  if facing == 'north' and direction == 'south' then
    turtle.turnLeft()
    turtle.turnLeft()
    facing = direction
  end
  if facing == 'north' and direction == 'west' then
    turtle.turnLeft()
    facing = direction
  end
  if facing == 'east' and direction == 'north' then
    turtle.turnLeft()
    facing = direction
  end
  if facing == 'east' and direction == 'south' then
    turtle.turnRight()
    facing = direction
  end
  if facing == 'east' and direction == 'west' then
    turtle.turnRight()
    turtle.turnRight()
    facing = direction
  end
  if facing == 'south' and direction == 'north' then
    turtle.turnRight()
    turtle.turnRight()
    facing = direction
  end
  if facing == 'south' and direction == 'east' then
    turtle.turnLeft()
    facing = direction
  end
  if facing == 'south' and direction == 'west' then
    turtle.turnRight()
    facing = direction
  end
  if facing == 'west' and direction == 'north' then
    turtle.turnRight()
    facing = direction
  end
  if facing == 'west' and direction == 'east' then
    turtle.turnRight()
    turtle.turnRight()
    facing = direction
  end
  if facing == 'west' and direction == 'south' then
    turtle.turnLeft()
    facing = direction
  end
end

local function toLocation(to)
  local location = { gps.locate() }
  if equals(to, location) then return end

  while location[2] ~= to[2] do
    if to[2] > location[2] then
      local success, _ = turtle.up()
      if not success then turtle.digUp() end
      location = { gps.locate() }
    else
      local success, _ = turtle.down()
      if not success then turtle.digDown() end
      location = { gps.locate() }
    end
  end

  while location[1] ~= to[1] do
    face('east')
    local success, _ = turtle.forward()
    if not success then turtle.dig() end
    location = { gps.locate() }
  end

  while location[3] ~= to[3] do
    if to[3] > location[3] then
      face('south')
      local success, _ = turtle.forward()
      if not success then turtle.dig() end
      location = { gps.locate() }
    else
      face('north')
      local success, _ = turtle.forward()
      if not success then turtle.dig() end
      location = { gps.locate() }
    end
  end
end

local function isOre(name)
  if string.match(name, 'raw_') or string.match(name, '_ore') or string.match(name, '_dust') then
    return true
  else
    return false
  end
end

local function equipTool(name)
  if name == 'minecraft:sand' or name == 'minecraft:gravel' or string.match(name, 'dirt') or name == 'minecraft:grass_block' then
    if currentTool == 'shovel' then
      return
    else
      turtle.select(2)
      turtle.equipLeft()
      turtle.select(1)

      currentTool = 'shovel'
    end
  else
    if currentTool == 'pickaxe' then
      return
    else
      turtle.select(2)
      turtle.equipLeft()
      turtle.select(1)

      currentTool = 'pickaxe'
    end
  end
end

local function mineStrip()
  local xToGo = sizeX
  while xToGo > 0 do
    local isBlock, data = turtle.inspectDown()
    if not isBlock then
      if xToGo == 1 then

      else
        local isBlock, data = turtle.inspect()
        if not isBlock then
          turtle.forward()
        else
          equipTool(data.name)
          turtle.dig()
          turtle.forward()
        end
      end
    else
      equipTool(data.name)
      if xToGo == 1 then
        turtle.digDown()
      else
        turtle.digDown()
        local isBlock, data = turtle.inspect()
        if not isBlock then
          turtle.forward()
        else
          equipTool(data.name)
          turtle.dig()
          turtle.forward()
        end
      end
    end

    xToGo = xToGo - 1
  end

  if facing == 'east' then
    if zToGo == 1 then return end
    turtle.turnLeft()
    local isBlock, data = turtle.inspect()
    if not isBlock then
      turtle.forward()
    else
      equipTool(data.name)
      turtle.dig()
      turtle.forward()
    end
    turtle.turnLeft()
    facing = 'west'
  elseif facing == 'west' then
    if zToGo == 1 then return end
    turtle.turnRight()
    local isBlock, data = turtle.inspect()
    if not isBlock then
      turtle.forward()
    else
      equipTool(data.name)
      turtle.dig()
      turtle.forward()
    end
    turtle.turnRight()
    facing = 'east'
  end
end

local function deposit()
  toLocation(startLoc)
  face('south')
  local loc = { gps.locate() }
  while not equals(startLoc, loc) do
    toLocation(startLoc)
    face('south')
    os.sleep(1)
  end

  local block, _ = turtle.inspectUp()
  while block == false do
    turtle.up()
    block, _ = turtle.inspectUp()
  end

  for i = 3, 16 do
    turtle.select(i)
    local item = turtle.getItemDetail()
    if item ~= nil then
      if isOre(item.name) then
        turtle.drop()
      else
        turtle.dropUp()
      end
    end
  end

  turtle.select(1)
end

local function start()
  local totalBlocks = 0
  if toYLevel < 0 then
    totalBlocks = (math.abs(toYLevel) + startLoc[2]) * (sizeX * sizeZ)
  else
    totalBlocks = (startLoc[2] - toYLevel) * (sizeX * sizeZ)
  end
  deposit()

  print(('Starting to mine a total of %s blocks'):format(totalBlocks))

  local rednetData = {
    op = 1,
    type = "turtle",
    label = os.getComputerLabel(),
    id = os.getComputerID(),
    fuel = fuelLevel,
    per = 0
  }

  rednet.send(rednetChannel, rednetData)

  for y = startLoc[2], toYLevel, -1 do
    face('west')
    local minFuel = (sizeX * sizeZ) + (sizeX + sizeZ - 1) + ((startY - (y - 1)) * 2)
    fuelLevel = turtle.getFuelLevel()
    while fuelLevel < minFuel do
      turtle.select(1)
      turtle.refuel(1)
      fuelLevel = turtle.getFuelLevel()
    end
    toLocation(current)
    current[2] = y - 1

    for _ = sizeZ, 1, -1 do
      zToGo = _
      mineStrip()
    end

    blocksMined = blocksMined + (sizeX * sizeZ)
    deposit()

    percent = string.format("%.2f", tostring((blocksMined / totalBlocks) * 100))
    rednetData.op = 7
    rednetData.fuel = fuelLevel
    rednetDate.per = percent

    rednet.send(rednetChannel, rednetData)
  end

  deposit()
end

start()
