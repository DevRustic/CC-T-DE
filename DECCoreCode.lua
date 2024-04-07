local modem = peripheral.wrap("left")
local rfStorage = peripheral.wrap("right")
 
print("Sending power stats on 69...")
 
while true do
  local timestamp = os.clock()
  local rfStored = rfStorage.getEnergyStored()
  local maxEnergy = rfStorage.getMaxEnergyStored()
  local msg = {timestamp, rfStored, maxEnergy}
  modem.transmit(69, 96, msg)
  os.sleep(5)
end