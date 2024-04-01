vehFunc = {}

local utils = require "modules.utils"

--- Get Vehicle Info By Plate
---@param plate string
function vehFunc.gvibp(plate)
    local vehInfo = lib.callback.await('rhd_garage:cb_server:getVehicleInfoByPlate', false, plate)
    return vehInfo and next(vehInfo) and vehInfo or false 
end

--- Get Outside Vehicle By Plate
---@param plate any
---@return integer | boolean
function vehFunc.govbp(plate)
    local Vehicles = GetGamePool("CVehicle")
    for i=1, #Vehicles do
        local entity = Vehicles[i]
        if DoesEntityExist(entity) then
            local vP = utils.getPlate(entity)
            if vP == plate then
                return entity
            end
        end
    end
    return false
end

--- Get Vehicle Properties
---@param vehicle string | integer
function vehFunc.gvp(vehicle)
    return lib.getVehicleProperties(vehicle)
end

---@param vehicle string | integer
---@param props table
function vehFunc.svp(vehicle, props)
    return lib.setVehicleProperties(vehicle, props)
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
        vehFunc.svp(veh, props)
    end

    if deformation then
        
    end
end)

--- exports
exports('trackOutVeh', trackOutVeh)
exports('getvehdataForPhone', getvehdataForPhone)
exports('getVehicleTypeByModel', getVehicleTypeByModel)
