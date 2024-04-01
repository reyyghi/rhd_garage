local utils = {}
local QBRadial = {}

local printType = {
    error = "^1[ERROR]^7",
    success = "^2[SUCCESS]^7"
}

---@param string string
---@return string?
string.trim = function ( string )
    if not string then return nil end
    return (string.gsub(string, '^%s*(.-)%s*$', '%1'))
end

---@param type string
---@param string string
function utils.print(type, string)
    if not type or not string then return end
    if not printType[type] then return end
    print(('%s %s'):format(printType[type], string))
end

---@param level any
function utils.getColorLevel(level)
    if not level then return end
    return level < 25 and "red" or level >= 25 and level < 50 and  "#E86405" or level >= 50 and level < 75 and "#E8AC05" or level >= 75 and "green"
end

---@param vehicle integer
---@param fuel number
function utils.setFuel(vehicle, fuel)
    Wait(100)
    if Config.FuelScript == "ox_fuel" then
        Entity(vehicle).state.fuel = fuel or 100
    else
        exports[Config.FuelScript]:SetFuel(vehicle, fuel or 100)
    end
end

---@param vehicle integer
function utils.getFuel(vehicle)
    local fuelLevel = 0
    if Config.FuelScript == "ox_fuel" then
        fuelLevel = Entity(vehicle).state?.fuel or 100 
    else
        fuelLevel = exports[Config.FuelScript]:GetFuel(vehicle)
    end
    return fuelLevel
end

---@param txt string
---@param type string
function utils.notify (txt, type)
    lib.notify({
        description = txt,
        type = type
    })
end

---@param vehicle integer
---@return string?
function utils.getPlate ( vehicle )
    if not DoesEntityExist(vehicle) then return end
    return GetVehicleNumberPlateText(vehicle):trim()
end

---@param plate string
---@return integer?
function utils.getoutsidevehicleByPlate( plate )
    local GameVeh = GetGamePool("CVehicle")
    for i=1, #GameVeh do
        local veh = GameVeh[i]
        if GetVehicleNumberPlateText(veh):trim() == plate then
            return veh
        end
    end

    return nil
end

function utils.getVehicleTypeByModel( model )
    model = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(model) then return end

    local vehicleType = GetVehicleClassFromName(model)
    local types = {
        [8] = "bike",
        [11] = "trailer",
        [13] = "bike",
        [14] = "boat",
        [15] = "heli",
        [16] = "plane",
        [21] = "train",
    }

    return types[vehicleType] or "automobile"
end

---@param model string | integer
---@param coords vector4
---@param cb fun(veh: integer)
---@param network boolean
---@return integer?
function utils.createPlyVeh ( model, coords, cb, network )
    network = network == nil and true or network
    lib.requestModel(model, 1500)
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, network, false)
    if network then
        local id = NetworkGetNetworkIdFromEntity(veh)
        SetNetworkIdCanMigrate(id, true)
        SetEntityAsMissionEntity(veh, true, true)
    end
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehRadioStation(veh, 'OFF')
    SetModelAsNoLongerNeeded(model)
    if cb then cb(veh) else return veh end
end

---@param vehType number
---@return string
function utils.classCheck ( vehType )
    local class = {
        [8] = "motorcycle",
        [13] = "cycles",
        [14] = "boat",
        [15] = "helicopter",
        [16] = "planes",
    }
    return class[vehType] or "car"
end

---@param action string
---@param ... unknown
---@return boolean|string|unknown
function utils.garageType ( action, ... )
    local result
    local args = {...}

    if action == "getstring" then
        result = ""
        if args[1] then
            for k, v in pairs(args[1]) do
                result = result .. ("%s%s"):format(v, next(args[1], k) and ", " or "")
            end
        end
    elseif action == "check" then
        result = false
        if args[1] and args[2] then
            if type(args[1]) == "string" then
                if args[1] == args[2] then
                    result = true
                end
            elseif type(args[1]) == "table" then
                for k, v in pairs(args[1]) do
                    if v == args[2] then
                        result = true
                    end
                end
            end
        end
    end

    return result
end

---@param class number
---@return string
function utils.getTypeByClass ( class )
    local vehType = 'car'
    if class == 14 then
        vehType = 'boat'
    elseif class == 16 then
        vehType = 'planes'
    elseif class == 15 then
        vehType = 'helicopter'
    end
    return vehType
end

---@param data table
---@return boolean
function utils.GangCheck ( data )
    local configGang = data.gang
    local playergang = fw.player.gang
    local allowed = false
    if type(configGang) == 'table' then
        local grade = configGang[playergang.name]
        allowed = grade and playergang.grade >= grade
    elseif type(configGang) == 'string' then
        if playergang.name == configGang then
            allowed = true
        end
    end
    return allowed
end

---@param data table
---@return boolean
function utils.JobCheck ( data )
    local configJob = data.job
    local playerjob = fw.player.job
    local allowed = false
    if type(configJob) == 'table' then
        local grade = configJob[playerjob.name]
        allowed = grade and playerjob.grade >= grade
    elseif type(configJob) == 'string' then
        if playerjob.name == configJob then
            allowed = true
        end
    end
    return allowed
end

---@param type string
---@param text string
---@param icon string
function utils.drawtext (type, text, icon)
    if type == 'show' then
        lib.showTextUI(text,{
            position = "left-center",
            icon = icon or '',
            style = {
                borderRadius= 5,
                backgroundColor = '#0985e3f8',
                color = 'white'
            }
        })
    elseif type == 'hide' then
        lib.hideTextUI()
    end
end

---@param data table
function utils.createMenu( data )
    lib.registerContext(data)
    lib.showContext(data.id)
end

---@param data table
function utils.createRadial ( data )
    if Config.RadialMenu == "qb" then
        QBRadial[data.id] = exports['qb-radialmenu']:AddOption({
            id = data.id,
            title = data.label,
            icon = data.icon == "parking" and "square-parking" or data.icon,
            type = 'client',
            event = data.event,
            garage = data.garage,
            shouldClose = true
        }, QBRadial[data.id])
    elseif Config.RadialMenu == "ox" then
        lib.addRadialItem({
            {
                id = data.id,
                label = data.label,
                icon = data.icon,
                onSelect = function ()
                    TriggerEvent(data.event, {garage = data.garage})
                end
            },
        })
    elseif Config.RadialMenu == "rhd" then
        exports.rhd_radialmenu:addRadialItem({
            id = data.id,
            label = data.label,
            icon = data.icon,
            action = function ()
                TriggerEvent(data.event, {garage = data.garage})
            end
        })
    end
end

---@param id string
function utils.removeRadial ( id )
    if Config.RadialMenu == "qb" then
        if QBRadial[id] then
            exports['qb-radialmenu']:RemoveOption(QBRadial[id])
        end
    elseif Config.RadialMenu == "ox" then
        lib.removeRadialItem(id)
    elseif Config.RadialMenu == "rhd" then
        exports.rhd_radialmenu:removeRadialItem(id)
    end
end

---@param self table
RegisterNetEvent("rhd_garage:radial:open", function (self)
    if not cache.vehicle then
        exports.rhd_garage:openMenu( {garage = self.garage.label, impound = self.garage.impound, shared = self.garage.shared, type = self.garage.type} )
    end
end)

---@param self table
RegisterNetEvent("rhd_garage:radial:store", function (self)
    local vehicle = cache.vehicle
    if not vehicle then
        vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped))
    end

    local vehicleType = utils.classCheck(GetVehicleClass(vehicle))
    if not utils.garageType("check", self.garage.type, vehicleType) then return
        utils.notify(locale('rhd_garage:invalid_vehicle_class', self.garage.label:lower()), "error")
    end

    if DoesEntityExist(vehicle) then
        if cache.vehicle then
            if cache.seat ~= -1 then return end
            TaskLeaveAnyVehicle(cache.ped, true, 0)
            Wait(1000)
        end

        exports.rhd_garage:storeVehicle({
            vehicle = vehicle,
            garage = self.garage.label,
            shared = self.garage.shared
        })
    else
        utils.notify(locale('rhd_garage:not_vehicle_exist'), 'error')
    end
end)

RegisterNetEvent('rhd_garage:radial:open_policeimpound', function(self)
    if not cache.vehicle then
        exports.rhd_garage:openpoliceImpound( self.garage )
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    
    if Config.RadialMenu == "qb-radialmenu" then
        for k,v in pairs(QBRadial) do
            exports['qb-radialmenu']:RemoveOption(v)
        end
    end
end)

if IsDuplicityVersion() then
    ---@param src number
    ---@param txt string
    ---@param type string
    function utils.ServerNotify(src, txt, type)
        lib.notify(src, {
            description = txt,
            type = type
        })
    end
end

return utils
