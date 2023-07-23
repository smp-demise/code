peripheral.find('modem', rednet.open)

local rednetData = {
  op = 1,
  type = "turtle",
  label = os.getComputerLabel(),
  id = os.getComputerID(),
  fuel = fuelLevel,
  per = 0
}

rednet.send(2, rednetData)
