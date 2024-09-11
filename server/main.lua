if not lib.checkDependency('ox_lib', '3.23.1') then error('This resource requires ox_lib version 3.23.1') end

local zones = lib.load('config.garages')
local storage = require 'modules.core.storage'

local _invoking = GetInvokingResource

---@param garageData garageZone
local function registerGarage(garageData)
    local duplicateLabel = Array.find(zones, function (data)
        if data.label == garageData.label then
            return true
        end
    end)

    assert(not duplicateLabel, (
        'A garage with the label "%s" already exists. Please choose a different label.'):format(garageData.label)
    )

    zones[#zones+1] = garageData
    TriggerClientEvent('rhd_garage:client:registerGarage', -1, garageData)
end

exports('AddGarage', registerGarage)

---@param label string
local function removeGarage(label)
    local index = Array.findIndex(zones, function (data)
        if data.label == label then
            return true
        end
    end) if not index then
        return
    end
    table.remove(zones, index)
    TriggerClientEvent('rhd_garage:client:removeGarage', -1, label)
end

exports('RemoveGarage', removeGarage)

lib.callback.register('rhd_garage:server:getGarageList', function ()
    return zones
end)

lib.callback.register('rhd_garage:server:checkAccess', function (src, garage)
    local player = PLAYERs[src]
    if not player then return end

    local data = addonGarage[garage]

    if not data then
        return 'gak ada'
    end

    return data.canAccess({
        playerId = src,
        name = player.name,
        identifier = player.identifier
    })
end)

lib.callback.register('rhd_garage:server:changeVehicleName', function (src, data)
    local player = PLAYERs[src]
    if not player then return end

    return storage.updateVehicle({
        filter = {
            identifier = player.identifier,
            plate = data.plate
        },
        update = {
            label = utils.string.trim(data.name)
        }
    })
end)

lib.callback.register('rhd_garage:server:changeGarage', function (src, data)
    local player = PLAYERs[src]
    if not player then return end

    return storage.updateVehicle({
        filter = {
            identifier = player.identifier,
            plate = data.plate
        },
        update = {
            garage = utils.string.trim(data.garage)
        }
    })
end)

lib.callback.register('rhd_garage:server:getVehicles', function(src, data)
    local player = PLAYERs[src]
    if not player then return end

    local state = data.depot and 0 or 1

    local filter = {
        state = state,
    }

    if not data.shared then
        filter.identifier = player.identifier
    end

    if not data.depot then
        filter.garage = data.garage
    end

    local vehicles = storage.getVehicles({
        select = '*',
        filter = filter,
    })

    return vehicles
end)

lib.callback.register('rhd_garage:server:getVehicleLocationByPlate', function (src, plate)
    local vehCoords
    local allvehicles = GetAllVehicles()
    
    Array.forEach(allvehicles, function (entity)
        local entityPlate = utils.vehicle.getPlate(entity)
        if entityPlate == plate then
            vehCoords = GetEntityCoords(entity)
        end
    end)

    if not vehCoords then
        local vehicleData = storage.getVehicleData({
            select = {
                'garage'
            },
            filter = {
                plate = plate
            }
        })
        local notifyText = 'Your vehicle is in the ' .. vehicleData.garage

        if vehicleData.garage == 'impounded' then
            notifyText = 'Your vehicle is at the depot'
        end
        
        utils.notify(src, notifyText)
        return false
    end

    return vehCoords
end)

lib.callback.register('rhd_garage:server:SaveVehicle', function(src, vehData)
    local player = PLAYERs[src]
    if not player then return end

    local mods = vehData.props
    local netId = vehData.netId
    local label = vehData.label
    local garage = vehData.garage
    local deformation = vehData.deformation or {}
    local plate = utils.string.trim(mods.plate --[[@as string]])
    
    local sharedGarage = Array.find(zones, function (data)
        if data.label == garage and data.type == 'shared' then
            return true
        end
    end)

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    local identifier = not sharedGarage and player.identifier

    local vehicleData = storage.getVehicleData({
        select = '1',
        filter = {
            identifier = identifier,
            plate = plate --[[@as string]]
        },
    })

    if vehicleData then
        local success = storage.updateVehicle({
            update = {
                label = label,
                garage = garage,
                state = 1,
                fuel = mods.fuelLevel --[[@as number]],
                engine = mods.engineHealth --[[@as number]],
                body = mods.bodyHealth --[[@as number]],
                properties = json.encode(mods),
                deformation = json.encode(deformation)
            },
            filter = {
                identifier = identifier,
                plate = plate,
            }
        })

        if not success then
            return
        end

        DeleteEntity(vehicle)
        return true
    end

    return false
end)

lib.callback.register('rhd_garage:server:SpawnVehicle', function(source, spawnData)
    local ped = GetPlayerPed(source)
    local entityOwner = NetworkGetEntityOwner(ped)
    local coords = spawnData.coords
    local warp = spawnData.warp
    local model = spawnData.model
    local plate = spawnData.plate
    local depotPayment = spawnData.depot
    local vehicleType = spawnData.class

    local Player = PLAYERs[source]
    if not Player then return end

    if depotPayment then
        if not Player.removeMoney(depotPayment.type, depotPayment.count) then
            utils.notify(source, 'You don\'t have money to pay the depot fee', 'error')
            return
        end
    end

    local vehEntity = CreateVehicleServerSetter(model, vehicleType, coords.x, coords.y, coords.z, coords.w)

    Wait(500)
    while GetVehicleNumberPlateText(vehEntity) == '' do
        Wait(0)
    end

    while not DoesEntityExist(vehEntity) do
        Wait(50)
    end

    if warp then
        SetPedIntoVehicle(ped, vehEntity, -1)
    end

    ---@source https://github.com/Qbox-project/qbx_core/blob/19c4ce3054811110cf1c4670fb1263cdf8f5841a/modules/lib.lua#L270
    local owner = pcall(function()
        lib.waitFor(function()
            local owner = NetworkGetEntityOwner(vehEntity)
            if owner == entityOwner then
                return true
            end
        end, 'client never set as owner', 5000)
    end)

    if not owner then
        DeleteEntity(vehEntity)
        error('Deleting vehicle which timed out finding an owner')
    end

    for i = -1, 0 do
        local pedInVehicle = GetPedInVehicleSeat(vehEntity, i)
        if pedInVehicle ~= ped then
            DeleteEntity(pedInVehicle)
        end
    end

    local vehicleData = storage.getVehicleData({
        select = {
            'identifier',
            'owner_name',
            'label',
            'plate',
            'properties',
            'deformation',
        },
        filter = {
            plate = plate
        }
    })

    local vState = Entity(vehEntity).state
    vState:set('owner', vehicleData.owner, true)
    vState:set('label', vehicleData.label, true)
    vState:set('plate', utils.string.trim(vehicleData.plate), true)
    vState:set('owner_identifier', vehicleData.identifier, true)

    local props, deformation = json.decode(vehicleData.properties), json.decode(vehicleData.deformation)
    local netId = NetworkGetNetworkIdFromEntity(vehEntity)

    TriggerClientEvent('vehiclekeys:client:SetOwner', source, plate)
    
    if props then
        vState:set('ox_lib:setVehicleProperties', props, true)
    end

   local success = storage.updateVehicle({
        filter = {
            plate = utils.string.trim(props.plate)
        },
        update = {
            state = 0
        }
    })

    if not success then
        DeleteEntity(vehEntity)
        error('Failed to update database')
    end

    return netId, props.fuelLevel, deformation
end)

RegisterNetEvent('rhd_garage:server:registerGarage', function(garageData)
    if _invoking() then return end
    registerGarage(garageData)
end)