utils = {}
utils.string = {}
utils.vehicle = {}
utils.context = {}

Array = lib.array

local getmakeNameFromVehicleModel = GetMakeNameFromVehicleModel
local getDisplayNameFromVehicleModel = GetDisplayNameFromVehicleModel
local getVehicleClassFromName = GetVehicleClassFromName

local config = require 'config.client'
local server = IsDuplicityVersion()

function utils.string.trim(s)
    if not s or type(s) ~= 'string' then return end
    local trimmed = s:gsub('^%s*(.-)%s*$', '%1')
    return trimmed
end

function utils.string.isEmpty(s)
    return s:match("^%s*$")
end

function utils.vehicle.getPlate( vehicle )
    if not DoesEntityExist(vehicle) then return end
    local vehPlate = GetVehicleNumberPlateText(vehicle)
    return utils.string.trim(vehPlate)
end

function utils.vehicle.getVehicleLabel(model)
    local brand = getmakeNameFromVehicleModel(model)
    local displayName = getDisplayNameFromVehicleModel(model)
    return ('%s %s'):format(brand, displayName)
end

function utils.vehicle.setFuel(vehicle, value)
    SetTimeout(150, function ()
        if config.fuelScript == "ox_fuel" then
            Entity(vehicle).state.fuel = value or 100
        else
            print(vehicle, value)
            exports[config.fuelScript]:SetFuel(vehicle, value or 100)
        end
    end)
end

function utils.vehicle.getFuel(vehicle)
    local fuelLevel = 0
    if config.fuelScript == "ox_fuel" then
        fuelLevel = Entity(vehicle).state?.fuel or 100 
    else
        fuelLevel = exports[config.fuelScript]:GetFuel(vehicle)
    end
    return fuelLevel
end

function utils.vehicle.getType(model)
    lib.requestModel(model, 1500)
    local vehicle = CreateVehicle(model, -5013.0049, -4318.3643, 510.5311, 308.5861, false, false)
    FreezeEntityPosition(vehicle, true)
    SetEntityCollision(vehicle, false, false)
    SetEntityAlpha(vehicle, 0, false)
    local vehicleType = GetVehicleType(vehicle)
    return vehicleType
end

function utils.getVehicleIcon(model)
    local icon = {
        [8] = "motorcycle",  --- Icon for motorcycles
        [13] = "bicycle",    --- Icon for bicycles
        [14] = "sailboat",   --- Icon for sailboats
        [15] = "helicopter", --- Icon for helicopters
        [16] = "plane",      --- Icon for planes
    }
    local class = getVehicleClassFromName(model)
    return icon[class] or 'car'
end

function utils.notify(msg, type, duration)
    lib.notify({
        description = msg,
        type = type,
        duration = duration or 5000
    })
end

if server then
    function utils.notify(src, msg, type, duration)
        lib.notify(src, {
            description = msg,
            type = type,
            duration = duration or 5000
        })
    end
else
    function utils.vehicle.isOutside(plate)
        local Vehicles = GetGamePool("CVehicle")
        return Array.find(Vehicles, function (entity)
            local Exist = DoesEntityExist(entity)
            local Dead = IsEntityDead(entity)
            
            if Dead then
                SetEntityAsMissionEntity(entity, true, true)
                DeleteEntity(entity)
            end

            if Exist and not Dead then
                local vP = utils.vehicle.getPlate(entity)
                if vP == plate then
                    return entity
                end
            end
        end)
    end
end