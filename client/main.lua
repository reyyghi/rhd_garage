local zones = lib.loadJson('data.garages')

local playerGarage = {}

local config = require 'config.client'
local garage = require 'modules.core.garage'

local _invoking = GetInvokingResource

CreateThread(function()
    repeat
        if config.InDevelopment then
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
    if not playerGarage[data.label] then
        playerGarage[data.label] = garage:new(data)
    end
end)

RegisterNetEvent('rhd_garage:client:removeGarage', function(label)
    if _invoking() then return end
    if not playerGarage[label] then
        return
    end
    playerGarage[label]:remove()
    playerGarage[label] = nil
end)