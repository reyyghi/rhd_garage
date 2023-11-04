if not Framework.esx() then return end

local esx = exports.es_extended:getSharedObject()

Framework.server = {}
Framework.server.GetPlayer = esx.GetPlayerFromId
Framework.server.removeMoney = function (source, type, amount)
    type = type == "cash" and "money" or type
    local ply = esx.GetPlayerFromId(source)
    if ply and ply ~= nil then
        ply.removeAccountMoney(type:lower(), amount, '')
        return true
    end

    return false
end

RegisterNetEvent('esx:playerLoaded', function(player, xPlayer, isNew)
    TriggerClientEvent("rhd_garage:client:loadedZone", xPlayer.source, GarageZone)
end)
