if GetCurrentResourceName() ~= "rhd_garage" then return end

vehFuncS = {}

local utils = lib.load("modules.utils")

--- Get Vehicle Out By Plate
---@param plate any
---@return table | boolean
function vehFuncS.govbp(plate)
    local veh = GetAllVehicles()
    for i=1, #veh do
        local entity = veh[i]
        local Plate = utils.getPlate(entity)
        if Plate == plate then
            return {
                exist = DoesEntityExist(entity),
                coords = GetEntityCoords(entity)
            }
        end
    end
    return false
end

lib.callback.register('rhd_garage:cb_server:GetPlayerVehiclesForPhone', function(source)
    return fw.gvfp(source)
end)

lib.callback.register('rhd_garage:cb_server:getoutsideVehicleCoords', function(_, plate, garage)
    local vehicle = vehFuncS.govbp(plate)
    local coords = vehicle and vehicle.exist and vehicle.coords or false
    if not coords and garage then
        local gz = GarageZone[garage]
        local gc = gz and gz.zones.points[1]
        coords = gz and gz.zones.points[1] or false
    end
    return coords
end)