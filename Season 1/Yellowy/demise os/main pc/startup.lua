local config = require "config"
term.clear()
term.setCursorPos(1, 1)

local devices = {}

print(("Computer is running on channel %i"):format(os.getComputerID()))
peripheral.find('modem', rednet.open)

while true do
  local id, msg = rednet.receive()
  if msg then
    term.setCursorPos(1, 2)
    term.clearLine()
    term.write(("Message recieved (%i | %i)"):format(msg.op, id))
    local op = msg.op
    if op == config.op.info then
      devices[msg.label] = {
        id = msg.id
      }

      if msg.type == 'turtle' then
        local data = {
          op = config.op.data,
          label = msg.label,
          fuel = msg.fuel,
          per = msg.per
        }
        rednet.send(devices['phone'].id, data)
      end
      rednet.send(msg.id, {
        op = 1
      })
    elseif op == config.op.ping then
      rednet.send(id, { op = config.op.ping })
    elseif op == config.op.data then
      local data = {
        op = config.op.data,
        label = msg.label,
        fuel = msg.fuel,
        per = msg.per
      }
      rednet.send(devices['phone'].id, data)
    end
  end
end
