if not Framework.esx() then return end

local ESX = exports.es_extended:getSharedObject()

Framework.client = {
    getMoney = function (type)
        local amount = 0
        local accounts = ESX.GetPlayerData().accounts
        type = type == "cash" and "money" or type
        for k, v in pairs(accounts) do
            if v.name == type then
                amount = v.money
            end
        end
        return amount
    end,
    getVehName = function (model)
        return GetDisplayNameFromVehicleModel(model)
    end,
    job = {},
    gang = {},
    playerName = ""
}

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded',function(xPlayer, isNew, skin)
    Framework.client.job = xPlayer.job
    Framework.client.gang = Framework.client.job
    Framework.client.playerName = LocalPlayer.state.name
    
    if not LocalPlayer.state.isLoggedIn then
        LocalPlayer.state:set("isLoggedIn", true, false)
    end
end)

RegisterNetEvent('esx:setJob', function(newJob)
    Framework.client.job = newJob
    Framework.client.gang = Framework.client.job
end)

CreateThread(function ()
    if LocalPlayer.state.isLoggedIn then
        Framework.client.job = LocalPlayer.state.job
        Framework.client.gang = Framework.client.job
        Framework.client.playerName = LocalPlayer.state.name
    end
end)
