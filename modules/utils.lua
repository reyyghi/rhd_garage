local utils = {}
local isServer = IsDuplicityVersion()
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

---@param garageType string
---@param Vehicle integer
---@return boolean
function utils.classCheck ( garageType, Vehicle )
    local VehClass = GetVehicleClass(Vehicle)
    if garageType == 'car' then
        if VehClass ~= 14 and VehClass ~= 15 and VehClass ~= 16 then return true end
    elseif garageType == 'boat' then
        if VehClass == 14 then return true end
    elseif garageType == 'planes' then
        if VehClass == 16 then return true end
    elseif garageType == 'helicopter' then
        if VehClass == 15 then return true end
    end
    return false
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
    if not utils.classCheck( self.garage.type, vehicle ) then return utils.notify(locale('rhd_garage:invalid_vehicle_class', self.garage.label:lower())) end
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

if isServer then
    --- QBOX Function (https://github.com/Qbox-project/qbx_core/blob/a4f2c0466e6ee113d799b6a08e56fb58f066f4a2/modules/utils.lua#L187C4-L187C4)
    -- If you don't use the above on the client, it will return 0 as the vehicle from the netid and 0 means no vehicle found because it doesn't exist so fast on the client
    -- Deletes vehicle ped is in before spawning a new one.
    ---@param source integer
    ---@param model string | integer
    ---@param coords? vector4 defaults to player's position
    ---@param warp? boolean
    ---@return integer? netId
    function utils.SpawnVehicle(source, model, coords, warp)
        model = type(model) == 'string' and joaat(model) or model

        if not CreateVehicleServerSetter then
            error('^1CreateVehicleServerSetter is not available on your artifact, please use artifact 5904 or above to be able to use this^0')
            return
        end

        local tempVehicle = CreateVehicle(model, 0, 0, 0, 0, true, true)
        while not DoesEntityExist(tempVehicle) do
            Wait(0)
        end
        local vehicleType = GetVehicleType(tempVehicle)
        DeleteEntity(tempVehicle)

        local ped = GetPlayerPed(source)
        if not coords then
            coords = GetCoordsFromEntity(ped)
        end

        local veh = CreateVehicleServerSetter(model, vehicleType, coords.x, coords.y, coords.z, coords.w)

        while not DoesEntityExist(veh) do
            Wait(0)
        end

        while GetVehicleNumberPlateText(veh) == "" do
            Wait(0)
        end

        if warp then SetPedIntoVehicle(ped, veh, -1) end
        Entity(veh).state:set('initVehicle', true, true)
        return NetworkGetNetworkIdFromEntity(veh)
    end
end


return utils
