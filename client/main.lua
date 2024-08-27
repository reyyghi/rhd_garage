local zones = lib.loadJson('data.garages')

local playerGarage = {}
local garage = require 'modules.garage.default'

local _invoking = GetInvokingResource

CreateThread(function()
    repeat
        if Config.InDevelopment then
            lib.print.info('Use the /reloadgarage command to reload the garage data.')
        end
        Wait(500)
    until PLAYER.loaded

    lib.array.forEach(zones, function (data)
        playerGarage[data.label] = garage:new(data)
    end)
end)

RegisterNetEvent('rhd_garage:client:registerGarage', function(data)
    if _invoking() then return end
    assert(not playerGarage[data.label], 'A garage with this label '..data.label..' already exists.')
    playerGarage[data.label] = garage:new(data)
end)

RegisterNetEvent('rhd_garage:client:removeGarage', function(label)
    if _invoking() then return end
    if not playerGarage[label] then return end
    playerGarage[label]:remove()
    playerGarage[label] = nil
end)