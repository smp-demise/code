term.clear()

local config = require "config"

local timeTimer = os.startTimer(0.01)
local connectTimer = os.startTimer(1)
local pingTimer = nil

local function clear(window)
  if window == nil then window = term end
  window.clear()
  window.setCursorPos(1, 1)
end

peripheral.find('modem', rednet.open)

local width, height = term.getSize()
local turtles = {}
local page = 1
local turtlesPerPage = config.turtlesPerPage

local connected = false
local gotPong = false

local clock = window.create(term.current(), 1, 1, 8, 1)
local reboot = window.create(term.current(), 9, 1, 9, 1)
local name = window.create(term.current(), 18, 1, 9, 1)
local turtle = window.create(term.current(), 1, 2, width, turtlesPerPage)
local console = window.create(term.current(), 1, height, width, 1)
clock.setBackgroundColor(colors.white)
clock.setTextColor(colors.black)
reboot.setBackgroundColor(colors.white)
reboot.setTextColor(colors.red)
reboot.write(" Reboot  ")
name.setBackgroundColor(colors.white)
name.setTextColor(colors.red)
name.write("Demise OS")

local function updateTime()
  local time = textutils.formatTime(os.time())
  clock.clear()
  clock.setCursorPos(1, 1)
  clock.write(time)
end

local function buttonxy(x, y)
  if ((9 < x) and (x < 17)) and (y == 1) then os.reboot() end
end

local function updateTurtles()
  local y = 1
  for k, v in pairs(turtles) do
    if y == turtlesPerPage then
    else
      turtle.setCursorPos(1, y)
      clear(console)
      -- turtle.write(("%s | %i | %i%%"):format(k, v.fuel, v.per))
      y = y + 1
    end
  end
end

local function eventHandler()
  local eventData = { os.pullEvent() }
  local event = eventData[1]

  if event == 'timer' then
    local timerId = eventData[2]
    if timerId == timeTimer then
      updateTime()
      timeTimer = os.startTimer(0.5)
    elseif timerId == connectTimer then
      if not connected then
        clear(console)
        console.write(("Not connected trying to connect"))

        rednet.send(config.computerId, {
          op = 1,
          type = 'pocket',
          label = os.getComputerLabel(),
          id = os.getComputerID()
        })

        connectTimer = os.startTimer(1)
      end
    elseif timerId == pingTimer then
      if not gotPong then
        connected = false
        connectTimer = os.startTimer(1)
        clear(name)
        name.setTextColor(colors.red)
        name.write('Demise OS')
      else
        gotPong = false
        rednet.send(config.computerId, { op = 2 })
      end
    end
  elseif event == 'mouse_click' then
    buttonxy(eventData[3], eventData[4])
  elseif event == 'rednet_message' then
    local msg = eventData[3]
    clear(console)
    console.write(('got op %i'):format(msg.op))
    if msg.op == 1 then
      clear(name)
      name.setTextColor(colors.green)
      name.write("Demise OS")
      connected = true
      pingTimer = os.startTimer(5)

      rednet.send(config.computerId, { op = 2 })
    elseif msg.op == 2 then
      gotPong = true
    elseif msg.op == 7 then
      turtles[msg.label] = msg
      clear(console)
      console.write(("turtle %s added"):format(msg.label))
      updateTurtles()
    end
  end
end

while true do
  eventHandler()
end
