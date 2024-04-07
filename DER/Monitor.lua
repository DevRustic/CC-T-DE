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

local targetStrength = 50
local maxTemperature = 8000
local safeTemperature = 3000
local lowestFieldPercent = 15

local activateOnCharged = 1
local autoInputGate = 1
local curInputGate = 222000

modem = peripheral.wrap("left")
monitor_peripheral = peripheral.wrap("right")
monitor = window.create(monitor_peripheral, 1, 1, monitor_peripheral.getSize())


modem.open(1337)

-- Helpers

local function isEmpty(message)
    return message == nil or message[2] == nil or type(message[2]) ~= "number"
end

monX, monY = monitor.getSize()
mon = {}
mon.monitor,mon.X, mon.Y = monitor, monX, monY

-- Monitor Update Function
function update()
    while true do
        monitor.setVisible(false)

        event, modemSide, senderChannel, replyChannel, message = os.pullEvent("modem_message")
        
        local status = message[1]
        local generationrate = message[2]
        local temperature = message[3]
        local energysaturation = message[4]
        local maxenergysaturation = message[5]
        local fieldstrength = message[6]
        local maxfieldstrength = message[7]
        local fuelconversion = message[8]
        local maxfuelconversion = message[9]

        local outputflow = message[10]
        local inputflow = message[11]

        local action = message[12]

        if temperature == nil then
            temperature = 20
        end
        if energysaturation == nil then
            energysaturation = 1
        end
        if maxenergysaturation == nil then
            maxenergysaturation = 1
        end
        if fieldstrength == nil then
            fieldstrength = 1
        end
        if maxfieldstrength == nil then
            maxfieldstrength = 1
        end
        if fuelconversion == nil then
            fuelconversion = 1
        end
        if maxfuelconversion == nil then
            maxfuelconversion = 1
        end
  
        f.clear(mon)

        print("Data Recieved on Channel 1337")
        print("")
        print(status)
        print(generationrate)
        print(temperature)
        print(energysaturation)
        print(maxenergysaturation)
        print(fieldstrength)
        print(maxfieldstrength)
        print(fuelconversion)
        print(maxfuelconversion)
        print("")
        print(outputflow)
        print(inputflow)
        print("")
        print(action)
  
        -- monitor output
  
        local statusColor
        statusColor = colors.red
  
        if status == "online" or status == "charged" then
          statusColor = colors.green
        elseif status == "offline" then
          statusColor = colors.gray
        elseif status == "charging" then
          statusColor = colors.orange
        end

        f.draw_text_lr(mon, 2, 2, 1, "Reactor Status", string.upper(status), colors.white, statusColor, colors.black)
  
        f.draw_text_lr(mon, 2, 4, 1, "Generation", f.format_int(generationrate) .. " rf/t", colors.white, colors.lime, colors.black)
  
        local tempColor = colors.red
        if temperature <= 5000 then tempColor = colors.green end
        if temperature >= 5000 and temperature <= 6500 then tempColor = colors.orange end
        f.draw_text_lr(mon, 2, 6, 1, "Temperature", f.format_int(temperature) .. "C", colors.white, tempColor, colors.black)
  
  
        f.draw_text_lr(mon, 2, 7, 1, "Output Gate", f.format_int(outputflow) .. " rf/t", colors.white, colors.blue, colors.black)
    
        f.draw_text_lr(mon, 2, 9, 1, "Input Gate", f.format_int(inputflow) .. " rf/t", colors.white, colors.blue, colors.black)
    
        if autoInputGate == 1 then
          f.draw_text(mon, 14, 10, "AU", colors.white, colors.gray)
        end
  
        local satPercent
        satPercent = math.ceil(energysaturation / maxenergysaturation * 10000)*.01
  
        f.draw_text_lr(mon, 2, 11, 1, "Energy Saturation", satPercent .. "%", colors.white, colors.white, colors.black)
        f.progress_bar(mon, 2, 12, mon.X-2, satPercent, 100, colors.blue, colors.gray)
  
        local fieldPercent, fieldColor
        fieldPercent = math.ceil(fieldstrength / maxfieldstrength * 10000)*.01
  
        fieldColor = colors.red
        if fieldPercent >= 50 then fieldColor = colors.green end
        if fieldPercent < 50 and fieldPercent > 30 then fieldColor = colors.orange end
  
        if autoInputGate == 1 then 
          f.draw_text_lr(mon, 2, 14, 1, "Field Strength T:" .. targetStrength, fieldPercent .. "%", colors.white, fieldColor, colors.black)
        else
          f.draw_text_lr(mon, 2, 14, 1, "Field Strength", fieldPercent .. "%", colors.white, fieldColor, colors.black)
        end
        f.progress_bar(mon, 2, 15, mon.X-2, fieldPercent, 100, fieldColor, colors.gray)
  
        local fuelPercent, fuelColor
  
        fuelPercent = 100 - math.ceil(fuelconversion / maxfuelconversion * 10000)*.01
  
        fuelColor = colors.red
  
        if fuelPercent >= 70 then fuelColor = colors.green end
        if fuelPercent < 70 and fuelPercent > 30 then fuelColor = colors.orange end
  
        f.draw_text_lr(mon, 2, 17, 1, "Fuel ", fuelPercent .. "%", colors.white, fuelColor, colors.black)
        f.progress_bar(mon, 2, 18, mon.X-2, fuelPercent, 100, fuelColor, colors.gray)
  
        f.draw_text_lr(mon, 2, 19, 1, "Action ", action, colors.gray, colors.gray, colors.black)

        monitor.setVisible(true) -- draw the screen.

        sleep(0)
    end
end


parallel.waitForAny(update)