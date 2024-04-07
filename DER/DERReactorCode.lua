-- modifiable variables
local reactorSide = "back"
local fluxgateSide = "right"

local targetStrength = 50
local maxTemperature = 8000
local safeTemperature = 3000
local lowestFieldPercent = 15

local activateOnCharged = 1

-- please leave things untouched from here on
local libURL = "https://raw.githubusercontent.com/acidjazz/drmon/master/lib/f.lua"
local lib
local libFile

fs.makeDir("lib")

lib = http.get(libURL)
libFile = lib.readAll()

local file1 = fs.open("lib/f", "w")
file1.write(libFile)
file1.close()

os.loadAPI("lib/f")

local version = "0.25"
-- toggleable via the monitor, use our algorithm to achieve our target field strength or let the user tweak it
local autoInputGate = 1
local curInputGate = 222000



-- peripherals
local reactor
local fluxgate
local inputfluxgate

-- reactor information
local ri

-- last performed action
local action = "None since reboot"
local emergencyCharge = false
local emergencyTemp = false

inputfluxgate = f.periphSearch("flow_gate")
fluxgate = peripheral.wrap(fluxgateSide)
reactor = peripheral.wrap(reactorSide)


if fluxgate == null then
	error("No valid fluxgate was found")
end

if reactor == null then
	error("No valid reactor was found")
end

if inputfluxgate == null then
	error("No valid flux gate was found")
end

--write settings to config file
function save_config()
  sw = fs.open("config.txt", "w")   
  sw.writeLine(version)
  sw.writeLine(autoInputGate)
  sw.writeLine(curInputGate)
  sw.close()
end

--read settings from file
function load_config()
  sr = fs.open("config.txt", "r")
  version = sr.readLine()
  autoInputGate = tonumber(sr.readLine())
  curInputGate = tonumber(sr.readLine())
  sr.close()
end


-- 1st time? save our settings, if not, load our settings
if fs.exists("config.txt") == false then
  save_config()
else
  load_config()
end




function update()
  while true do 

    ri = reactor.getReactorInfo()

    -- print out all the infos from .getReactorInfo() to term

    if ri == nil then
      error("reactor has an invalid setup")
    end

    for k, v in pairs (ri) do
      print(k.. ": "..tostring(v))			
    end
    print("Output Gate: ", fluxgate.getSignalLowFlow())
    print("Input Gate: ", inputfluxgate.getSignalLowFlow())


    -- actual reactor interaction
    --
    if emergencyCharge == true then
      reactor.chargeReactor()
    end
    
    -- are we charging? open the floodgates
    if ri.status == "charging" then
      inputfluxgate.setSignalLowFlow(900000)
      emergencyCharge = false
    end

    -- are we stopping from a shutdown and our temp is better? activate
    if emergencyTemp == true and ri.status == "stopping" and ri.temperature < safeTemperature then
      reactor.activateReactor()
      emergencyTemp = false
    end

    -- are we charged? lets activate
    if ri.status == "charged" and activateOnCharged == 1 then
      reactor.activateReactor()
    end

    -- are we on? regulate the input fludgate to our target field strength
    -- or set it to our saved setting since we are on manual
    if ri.status == "online" then
      if autoInputGate == 1 then 
        fluxval = ri.fieldDrainRate / (1 - (targetStrength/100) )
        print("Target Gate: ".. fluxval)
        inputfluxgate.setSignalLowFlow(fluxval)
      else
        inputfluxgate.setSignalLowFlow(curInputGate)
      end
    end

    -- safeguards
    --
    
    -- out of fuel, kill it
    if fuelPercent <= 10 then
      reactor.stopReactor()
      action = "Fuel below 10%, refuel"
    end

    -- field strength is too dangerous, kill and it try and charge it before it blows
    if fieldPercent <= lowestFieldPercent and ri.status == "online" then
      action = "Field Str < " ..lowestFieldPercent.."%"
      reactor.stopReactor()
      reactor.chargeReactor()
      emergencyCharge = true
    end

    -- temperature too high, kill it and activate it when its cool
    if ri.temperature > maxTemperature then
      reactor.stopReactor()
      action = "Temp > " .. maxTemperature
      emergencyTemp = true
    end

    sleep(0)
  end
end

local modem = peripheral.wrap("left")

print("Sending stats on 1337...")

while true do
    ri = reactor.getReactorInfo()
    local status = ri.status
    local generationRate = ri.generationRate
    local temperature = ri.temperature
    local energysaturation = ri.energySaturation
    local maxenergysaturation = ri.maxEnergySaturation
    local fieldstrength = ri.fieldStrength
    local maxfieldstrength = ri.maxFieldStrength
    local fuelconversion = ri.fuelConversion
    local maxfuelconversion = ri.maxFuelConversion



    local msg = {status, generationRate, temperature, energysaturation, maxenergysaturation, fieldstrength, maxfieldstrength, fuelconversion, maxfuelconversion}
    modem.transmit(1337, 1337, msg)
    os.sleep(1)
  end

parallel.waitForAny(buttons, update)