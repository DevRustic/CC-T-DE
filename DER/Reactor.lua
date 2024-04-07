-- Modifiable variables

local reactorSide = "back"
local fluxgateSide = "right"

-- Load API
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


-- Peripherals and Init
local reactor
local fluxgate
local inputfluxgate

local targetStrength = 50
local maxTemperature = 8000
local safeTemperature = 3000
local lowestFieldPercent = 15
local autoInputGate = 1

local action = "None since reboot"

modem = peripheral.wrap("left")

inputfluxgate = peripheral.wrap("bottom")
fluxgate = peripheral.wrap(fluxgateSide)
reactor = peripheral.wrap(reactorSide)

local ri

modem = peripheral.wrap("left")

-- Checks
if fluxgate == null then
	error("No valid fluxgate was found")
end

if reactor == null then
	error("No valid reactor was found")
end

if inputfluxgate == null then
	error("No valid flux gate was found")
end

function ReactorUpdate()
    while true do 
        ri = reactor.getReactorInfo()

        outputflow = fluxgate.getSignalLowFlow()
        inputflow = inputfluxgate.getSignalLowFlow()

        msg = {ri.status, ri.generationRate, ri.temperature, ri.energySaturation, ri.maxEnergySaturation, ri.fieldStrength, ri.maxFieldStrength, ri.fuelConversion, ri.maxFuelConversion, outputflow, inputflow, action}

        modem.transmit(1337, 1337, msg)


                    -- actual reactor interaction
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
        if ri.status == "running" then
            fluxval = ri.fieldDrainRate / (1 - (targetStrength/100) )
            print("Target Gate: ".. fluxval)
            inputfluxgate.setSignalLowFlow(fluxval)
        end
  
          -- safeguards
          --
          local fuelPercent

          fuelPercent = 100 - math.ceil(ri.fuelConversion / ri.maxFuelConversion * 10000)*.01
          -- out of fuel, kill it
        if fuelPercent ~= nil and fuelPercent <= 10 then
            reactor.stopReactor()
            action = "Fuel below 10%, refuel"
        end
          local fieldPercent
          fieldPercent = math.ceil(ri.fieldStrength / ri.maxFieldStrength * 10000)*.01

          -- field strength is too dangerous, kill and it try and charge it before it blows
        if fieldPercent ~= nil and fieldPercent <= lowestFieldPercent and ri.status == "online" then
            action = "Field Str < " ..lowestFieldPercent.."%"
            reactor.stopReactor()
        end
  
          -- temperature too high, kill it and activate it when its cool
        if ri.temperature ~= nil and ri.temperature > maxTemperature then
            reactor.stopReactor()
            action = "Temp > " .. maxTemperature
            emergencyTemp = true
        end

        os.sleep(0)
    end
end

parallel.waitForAny(ReactorUpdate)