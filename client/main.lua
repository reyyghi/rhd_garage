
local playerGarage = {}

local _invoking = GetInvokingResource
local garage = require 'modules.core.garage'

RegisterNetEvent('rhd_garage:client:loadGarage', function(garageList)
    if _invoking() then return end
    if Array.isArray(garageList) then
        for i=1, #garageList do
            local data = garageList[i]
            if not data.index then data.index = i end
            playerGarage[data.label] = garage:new(data)
        end
    end
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