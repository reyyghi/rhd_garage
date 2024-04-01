local utils = require "modules.utils"
vehFunc = {}

--- Get Vehicle Info By Plate
---@param plate string
function vehFunc.gvibp(plate)
    local vehInfo = lib.callback.await('rhd_garage:cb_server:getVehicleInfoByPlate', false, plate)
    return vehInfo and next(vehInfo) and vehInfo or false 
end

local function getvehdataForPhone ( )
    return lib.callback.await('rhd_garage:cb_server:getvehdataForPhone', false)
end

---@param plate string
local function trackOutVeh ( plate )
    local coords = nil
    local plate = plate:trim()
    local vehExist = utils.getoutsidevehicleByPlate(plate)
    
    if DoesEntityExist(vehExist) then
        coords = GetEntityCoords(vehExist)
        SetNewWaypoint(coords.x, coords.y)
    end
end

---@param model string|integer
---@return string|nil
local function getVehicleTypeByModel ( model )
    return utils.getVehicleTypeByModel( model )
end

---callback
lib.callback.register('rhd_garage:cb_client:vehicleSpawned', function(netId, props, deformation)
    local veh = NetworkGetEntityFromNetworkId(netId)

    for i = -1, 0 do
        local ped = GetPedInVehicleSeat(veh, i)
        if ped ~= cache.ped and ped > 0 and NetworkGetEntityOwner(ped) == cache.playerId then
            DeleteEntity(ped)
        end
    end

    if props then
        lib.setVehicleProperties(veh, props)
    end

    if deformation then
        
    end
end)

--- exports
exports('trackOutVeh', trackOutVeh)
exports('getvehdataForPhone', getvehdataForPhone)
exports('getVehicleTypeByModel', getVehicleTypeByModel)
