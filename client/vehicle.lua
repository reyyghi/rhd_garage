local utils = require "modules.utils"

--- function
---@param plate string
---@return table | boolean
local function getvehdataByPlate ( plate )
    local Data = lib.callback.await("rhd_garage:cb_server:getvehicledatabyplate", false, plate:trim())
    return next(Data) and Data or false
end

local function getvehdataForPhone ( )
    if not Framework.qb() then
        return
    end

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
lib.callback.register('rhd_garage:cb_client:cekEntityVeh', function (plate)
    if utils.getoutsidevehicleByPlate(plate:trim()) then
        return true
    end
    return false
end)

--- exports
exports('trackOutVeh', trackOutVeh)
exports("getvehdataByPlate", getvehdataByPlate)
exports('getvehdataForPhone', getvehdataForPhone)
exports('getVehicleTypeByModel', getVehicleTypeByModel)
