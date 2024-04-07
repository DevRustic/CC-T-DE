local modem = peripheral.wrap("left")
local monitor_peripheral = peripheral.wrap("right")

local status = 1000
local generationRate = 1000
local temperature = 1000
local energysaturatio>n = 1000
local maxenergysaturation = 1000
local fieldstrength = 1000
local maxfieldstrength = 1000
local fuelconversion = 1000
local maxfuelconversion = 1000

local STORE = {}
local maxStoreCount = 2000

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



-- monitor 
local mon, monitor, monX, monY

monitor = window.create(monitor_peripheral, 1, 1, monitor_peripheral.getSize()) -- create a window on the monitor

 
local function removeOldMsgs()
    local msgCount = table.getn(STORE)
    if msgCount > maxStoreCount then
        for i = 1, 500 do -- remove oldest 500 msgs. This way this function doesn't have to run often
            table.remove(STORE, 1)
        end
    end
end

monX, monY = monitor.getSize()
mon = {}
mon.monitor,mon.X, mon.Y = monitor, monX, monY


  
  
  
  function update()
    local lastMsgN = table.getn(STORE)
    if lastMsgN > 0 then
        local lastMsg = STORE[lastMsgN]

        local status = lastMsg[0]
        local generationRate = lastMsg[1]
        local temperature = lastMsg[2]
        local energysaturation = lastMsg[3]
        local maxenergysaturation = lastMsg[4]
        local fieldstrength = lastMsg[5]
        local maxfieldstrength = lastMsg[6]
        local fuelconversion = lastMsg[7]
        local maxfuelconversion = lastMsg[8]
    end

    while true do 
  
      monitor.setVisible(false) -- disable updating the screen.
      f.clear(mon)
  
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
          
      f.draw_text_lr(mon, 2, 2, 1, "Reactor Status", status, colors.white, statusColor, colors.black)
  
      f.draw_text_lr(mon, 2, 4, 1, "Generation", f.format_int(generationRate) .. " rf/t", colors.white, colors.lime, colors.black)
  
      local tempColor = colors.red
      if temperature <= 5000 then tempColor = colors.green end
      if temperature >= 5000 and temperature <= 6500 then tempColor = colors.orange end
      f.draw_text_lr(mon, 2, 6, 1, "Temperature", f.format_int(temperature) .. "C", colors.white, tempColor, colors.black)
  
  
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

      monitor.setVisible(true)
    end
end

    local function isEmpty(msg)
        return msg == nil or msg[2] == nil or type(msg[2]) ~= "number"
      end

local function listen()
    -- open connection
    modem.open(1337)

    print("Listening for Data....")
    while true do
        local e,s,f,re,msg,d = os.pullEvent("modem_message")
        
        if not isEmpty(msg) then  
            -- update store
            table.insert(STORE, msg)
            removeOldMsgs() -- don't want STORE getting too big
            print("stuff")
            update()
            
        end
    end
end


listen()