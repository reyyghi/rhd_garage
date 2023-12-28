local utils = {}
local QBRadial = {}

---@param string string
---@return string?
string.trim = function ( string )
    if not string then return nil end
    return (string.gsub(string, '^%s*(.-)%s*$', '%1'))
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
function utils.gerageType ( action, ... )
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
function utils.gangCheck ( data )
    local configGang = data.gang
    local plyJob = Framework.playerGang()
    if type(configGang) == 'table' then
        for job, grade in pairs(configGang) do      
            if type(plyJob.grade) == 'table' then
                plyJob.grade = plyJob.grade.level
            end
            if plyJob.name == job and plyJob.grade >= grade then
                return true
            end
        end
    elseif type(configGang) == 'string' then
        if plyJob.name == configGang then
            return true
        end
    end
    return false
end

---@param data table
---@return boolean
function utils.JobCheck ( data )
    local configJob = data.job
    local plyJob = Framework.playerJob()
    if type(configJob) == 'table' then
        for job, grade in pairs(configJob) do         
            if type(plyJob.grade) == 'table' then
                plyJob.grade = plyJob.grade.level
            end

            if plyJob.type then
                if plyJob.type == job and plyJob.grade >= grade then
                    return true
                end
            end

            if plyJob.name == job and plyJob.grade >= grade then
                return true
            end
        end
    elseif type(configJob) == 'string' then
        if plyJob.name == configJob then
            return true
        end
    end
    return false
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
            icon = ("#%s"):format(data.icon),
            type = "clientFunction",
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
        Garage.openMenu( {garage = self.garage.label, impound = self.garage.impound, shared = self.garage.shared, type = self.garage.type} )
    end
end)

---@param self table
RegisterNetEvent("rhd_garage:radial:store", function (self)
    local vehicle = cache.vehicle
    if not vehicle then
        vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped))
    end

    local vehicleType = utils.classCheck(GetVehicleClass(vehicle))
    if not utils.gerageType("check", self.garage.type, vehicleType) then return
        utils.notify(locale('rhd_garage:invalid_vehicle_class', self.garage.label:lower()), "error")
    end

    if DoesEntityExist(vehicle) then
        if cache.vehicle then
            if cache.seat ~= -1 then return end
            TaskLeaveAnyVehicle(cache.ped, true, 0)
            Wait(1000)
        end

        Garage.storeVeh({
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
        PoliceImpound.open( self.garage )
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

return utils
