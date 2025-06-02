console = getBot():getConsole()

worlds = {
    -- "PAISEED99|PUKIMEKZ",
    "PAISEED109|PUKIMEKZ",
    "PAISEED119|PUKIMEKZ",
}

save_world = "I0L|HEHEHE"
item = {
    6962, -- Bloccoli
    6960, -- Carrot
    2034, -- Comet Dust
    2036, -- Antimatter Dust
}

function canReach(x, y)
    return #getBot():getPath(x, y) > 0 or getBot():isInTile(x, y)
end

local function checkOffline()
    local console = getBot():getConsole()
    local hardlogin = 0

    while getBot().status ~= BotStatus.online do
        getBot().auto_reconnect = false

        if getBot().status == BotStatus.account_banned or getBot().status == BotStatus.account_suspended then 
            print("Oh no " .. getBot().name .. " account got banned!")
            sendWebhook(getBot().status)
            warningWebhook()
            getBot():stopScript()
        end

        if hardlogin >= 3 then
            console:append("`o[`4WARNING`o] LOGIN STUCK, Adding `220 `oseconds delay..")
            getBot():disconnect()
            sleep(20000)
            hardlogin = 0
        end

        console:append("`o[`4WARNING`o] Bot is offline, reconnecting..")
        getBot():connect()
        hardlogin = hardlogin + 1
        sleep(10000)
    end

    getBot().auto_reconnect = true
end

local function warpID(world, door)
    local console = getBot():getConsole()   
    local hardwarp = 0

    while getBot():getWorld().name:lower() ~= world:lower() do
        checkOffline()

        if hardwarp >= 3 then
            console:append("`o[`4WARNING`o] HARD WARP, Adding `215 `oseconds delay..")
            getBot():disconnect()
            sleep(15000)
            getBot():connect()
            hardwarp = 0
        end

        getBot():warp(world)
        sleep(8000)

        hardwarp = hardwarp + 1
    end

    if door then
        while getTile(getBot().x, getBot().y).fg == 6 do
            getBot():warp(world, door)
            sleep(3000)
        end
    end
    console:append("`o[`2INFO`o] Arrived at `2" .. world)
end

getBot().auto_collect = false
for _, entry in ipairs(worlds) do
    local world_name, door = entry:match("([^|]+)|([^|]+)")
    warpID(world_name, door)

    for __, id in ipairs(item) do
        for _, obj in ipairs(getObjects()) do
            -- print(getInfo(obj.id).name)
            if obj.id == id then
                local x, y = obj.x // 32, obj.y // 32
                getBot():getConsole():append("`o[`2INFO`o] Found `0" .. getInfo(id).name .. "`o at `0(" .. x .. ", " .. y .. ")`o!")

                while getBot().x ~= x and getBot().y ~= y do
                    if not canReach(x, y) then
                        console:append("`o[`2INFO`o] Cant Reach `0(" .. x .. ", " .. y ..")")
                        goto continue
                    end
                    getBot():findPath(x, y)
                end
                sleep(500)

                
                local current = getBot():getInventory():getItemCount(id)
                while getBot():getInventory():getItemCount(id) == current do
                    if getBot():getInventory():getItemCount(id) == 200 then
                        getBot():getConsole():append("`o[`2INFO`o] `0" .. getInfo(id).name .. "`o is full!")
                        save_name, save_door = save_world:match("([^|]+)|([^|]+)")
                        warpID(save_name, save_door)

                        for __, id in ipairs(item) do
                            getBot():findOutput()
                            getBot():getConsole():append("`o[`2INFO`o] Dropping `0" .. getBot():getInventory():getItemCount(id) .. "`2 " .. getInfo(id).name .. "`o!")
                            getBot():drop(id, getBot():getInventory():getItemCount(id))
                            sleep(1000)
                        end

                        warpID(world_name, door)
                    end
                    getBot():collectByID(id)
                    sleep(500)
                end
                sleep(1000)
            end
            ::continue::
        end
    end
    sleep(2000)
end

save_name, save_door = save_world:match("([^|]+)|([^|]+)")
warpID(save_name, save_door)

for __, id in ipairs(item) do
    getBot():findOutput()
    getBot():getConsole():append("`o[`2INFO`o] Dropping `0" .. getBot():getInventory():getItemCount(id) .. "`2 " .. getInfo(id).name .. "`o!")
    getBot():drop(id, getBot():getInventory():getItemCount(id))
    sleep(1000)
end

getBot():getConsole():append("`o[`2INFO`o] Dropped all items!")
getBot():warp("EXIT")
getBot().auto_reconnect = false
getBot():disconnect()

