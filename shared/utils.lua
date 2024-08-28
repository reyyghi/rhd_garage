utils = {}
utils.string = {}
utils.vehicle = {}
utils.context = {}

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

function utils.context.getVehicleIcon(model)
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

function utils.context.openMenu(context)
    lib.registerContext(context)
    lib.showContext(context.id)
end

function utils.context.getColourScheme(val)
    if not val then return end
    return val < 25 and "red" or val >= 25 and val < 50 and  "#E86405" or val >= 50 and val < 75 and "#E8AC05" or val >= 75 and "green"
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
end