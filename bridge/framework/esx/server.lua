if not Framework.esx() then return end

local esx = exports.es_extended:getSharedObject()

Framework.server = {
    removeMoney = function (source, type, amount)
        type = type == "cash" and "money" or type
        local ply = esx.GetPlayerFromId(source)
        if ply and ply ~= nil then
            ply.removeAccountMoney(type:lower(), amount, '')
            return true
        end
    
        return false
    end,
    getIdentifier = function (source)
        return esx.GetPlayerFromId(source)?.identifier or false
    end,
    getName = function (source)
        return esx.GetPlayerFromId(source)?.getName() or "unknown"
    end,
    GetPlayerFromCitizenid = esx.GetPlayerFromIdentifier,
}

RegisterNetEvent('esx:playerLoaded', function(player, xPlayer, isNew)
    GlobalState.rhd_garage_zone = GarageZone
end)
