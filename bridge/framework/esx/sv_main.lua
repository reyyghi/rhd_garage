if GetResourceState('es_extended') == "missing" then return end

local ESX = exports["es_extended"]:getSharedObject()

PLAYERs = {}
Framework = {}

---@class server : OxClass
local server = lib.class('server')

function server:constructor(xPlayer)
    
    self.source = xPlayer.source
    self.identifier = xPlayer.identifier
    self.getName = xPlayer.getName
    self.removeMoney = xPlayer.removeAccountMoney

    self.getMoney = function (type)
        type = type == 'cash' and 'money' or type
        local money = xPlayer.getAccount(type).money
        return money or 0
    end

    self.removeMoney = function (type, count)
        type = type == 'cash' and 'money' or type
        if self.getMoney(type) >= count then
            xPlayer.removeAccountMoney(type, count)
            return true
        end
        return false
    end

    return self
end

lib.load('bridge.framework.esx.storage.main')

function Framework.getPlayerByIdentifier(identifier)
    for _, xPlayer in pairs(PLAYERs) do
        if xPlayer.identifier == identifier then
            return xPlayer
        end
    end
    return false
end

function Framework.getVehicles(filter, ownerData)
    local vehicles = vehStorage.fetchPlayerVehicles({
        filter = filter,
        ownerData = ownerData
    })
    return vehicles
end

AddEventHandler("esx:playerLoaded", function(_, xPlayer)
    if PLAYERs[xPlayer.source] then return end

    PLAYERs[xPlayer.source] = server:new(xPlayer)
    xPlayer.triggerEvent('rhd_garage:reloadgarage', xPlayer)
end)

AddEventHandler('playerDropped', function (reason)
    local src = source
    if PLAYERs[src] then
        PLAYERs[src] = nil
    end
end)

if Config.InDevelopment then
    lib.addCommand('reloadgarage', {
        help = 'Use this command if you have finished restarting this resource.',
        restricted = 'group.admin'
    }, function(source, args, raw)
        local xPlayer = ESX.GetPlayerFromId(source)

        PLAYERs[xPlayer.source] = server:new(xPlayer)
        xPlayer.triggerEvent('rhd_garage:reloadgarage', xPlayer)
    end)
end

-- RegisterCommand('testaja', function (src)
--     local player = PLAYERs[src]
--     local okontol = player.identifier
    
--     local vehicles = player.getVehicles({
--         identifier = okontol,
--         stored = 1,
--         garage = 'Motel Parking',
--     })

--     if lib.array.isArray(vehicles) then
--         lib.array.forEach(vehicles, function (veh)
--             print(json.encode(veh, {indent = true}))
--         end)
--     end
-- end, false)