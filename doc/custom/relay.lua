local event = require("event")
local component = require("component")
local os = require("os")
local relay = {}

local function formatMessage(...)
    ---@class message
    ---@field eventType string
    ---@field receiverAddress string
    ---@field senderAddress string
    ---@field port number
    ---@field distance number
    ---@field data any[]
    local mdl = {}
    local allData = { ... }
    mdl.eventType = allData[1]
    mdl.receiverAddress = allData[2]
    mdl.senderAddress = allData[3]
    mdl.port = allData[4]
    mdl.distance = allData[5]
    mdl.data = {}

    for i = 6, #allData do
        table.insert(mdl.data, allData[i])
    end
    return mdl
end

---improve modem
---@param modem modem
---@return avModem
function relay.Modem(modem)
    ---@class avModem : modem
    ---@field mo modem
    local mdl = modem

    ---@param port number
    function mdl.broadcastPingMessage(port, ...)
        mdl.open(port + 1)
        --print(mdl.isOpen(port+1))
        for i = 1, 3 do
            mdl.broadcast(port, ...)
            --print("send")
            ---@type string, string , string, number, number
            local _, _, _, _, _, message = event.pull(3, "modem_message")

            if message == "receive" then
                break
            end
        end
        mdl.close(port + 1)
    end

    ---@param address string
    ---@param port number
    function mdl.sendPingMessage(address, port, ...)
        mdl.open(port + 1)
        for i = 1, 3 do
            mdl.send(address, port, ...)
            --print("send")
            ---@type string, string , string, number, number
            local _, _, senderAddress, _, _, message = event.pull(3, "modem_message")

            if address == senderAddress and message == "receive" then
                break
            end
        end
        mdl.close(port + 1)
    end

    return mdl
end

---improve tunnel
---@param tunnel tunnel
---@return avTunnel
function relay.Tunnel(tunnel)
    ---@class avTunnel : tunnel
    local mdl = tunnel

    function mdl.sendPingMessage(...)
        for i = 1, 3 do
            mdl.send(...)
            --print("send")
            ---@type string, string , string, number, number,any...
            local _, _, _, _, _, message = event.pull(3, "modem_message")
            if message == "receive" then
                break
            end
        end
    end
    return mdl
end

---@param modem modem
function relay:setComponentModem(modem)
    self.modem = modem
end

---@param tunnel tunnel
function relay:setComponentTunnel(tunnel)
    self.tunnel = tunnel
end

function relay:receivePingMessage()
    local data = formatMessage(event.pull("modem_message"))
    os.sleep(0.5)
    if data.port == 0 then
        self.tunnel.send("receive")
    else
        --print("send")
        self.modem.send(data.senderAddress, data.port + 1, "receive")
    end
    --print("receive message from " .. data.senderAddress)
    return data
end

return relay