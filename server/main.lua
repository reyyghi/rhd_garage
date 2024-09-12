if not lib.checkDependency('ox_lib', '3.24.0') then error('This resource requires ox_lib version 3.24.0') end

local zones = lib.load('config.garages')
local storage = require 'modules.core.storage'

function PrepareGarage(source)
    TriggerClientEvent('rhd_garage:client:loadGarage', source, zones)
end

---@param logs vehicleLogs[]
---@param newlogs vehicleLogs
local function insertLogs(logs, newlogs)
    if Array.isArray(logs) then
        if #logs > 50 then
            for i=1, 25 do
                table.remove(logs, i)
                Wait(500)
            end
        end
        logs[#logs+1] = newlogs
    end
end

---@param garage garageZone
local function getSpawnLocation(garage)
    if garage.spawnPoint then
        return Array.find(garage.spawnPoint, function (coords)
            local sp = vec(coords.x, coords.y, coords.z, coords.w)
            local vehEntity = lib.getClosestVehicle(sp.xyz, 3.0, true)
            if not vehEntity then
                return sp
            end
        end)
    elseif garage.points?.save then
        local coords = garage.points?.save
        local sp = vec(coords.x, coords.y, coords.z, coords.w)
        local vehEntity = lib.getClosestVehicle(sp.xyz, 3.0, true)
        if not vehEntity then
            return sp
        end
    end
    return false
end

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

    local index = #zones + 1
    garageData.index = index
    zones[index] = garageData
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

    local garageData = zones[garage]
    if not garageData then
        return
    end

    return garageData.canAccess({
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

    local garageData = zones[vehData.garage]
    if not garageData then return end

    local mods = vehData.props
    local netId = vehData.netId
    local label = vehData.label
    
    local deformation = vehData.deformation or {}
    local plate = utils.string.trim(mods.plate --[[@as string]])
    
    local sharedGarage = garageData.type == 'shared'

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    local identifier = not sharedGarage and player.identifier

    local vehicleData = storage.getVehicleData({
        select = {
            'logs',
        },
        filter = {
            identifier = identifier,
            plate = plate --[[@as string]]
        },
    })

    
    if vehicleData then
        local logs = json.decode(vehicleData.logs)

        insertLogs(logs, {
            whodo = player.name,
            status = 'Stored',
            date = os.date("%d-%m-%Y %H:%M:%S"),
            garage = garageData.label .. ' ('..garageData.type..')'
        })

        local success = storage.updateVehicle({
            update = {
                label = label,
                garage = garageData.label,
                state = 1,
                fuel = mods.fuelLevel --[[@as number]],
                engine = mods.engineHealth --[[@as number]],
                body = mods.bodyHealth --[[@as number]],
                properties = json.encode(mods),
                deformation = json.encode(deformation),
                logs = json.encode(logs)
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
    
    local garage = spawnData.garage
    local garageData = zones[garage]

    if not garageData then
        return
    end

    local warp = spawnData.warp
    local model = spawnData.model
    local plate = spawnData.plate
    local depotPayment = spawnData.payment
    local vehicleType = spawnData.vehicleType
    local vehicleClass = spawnData.vehicleClass

    local Player = PLAYERs[source]
    if not Player then return end

    local logGarage = garageData.label .. ' ('..garageData.type..')'

    if depotPayment then
        local depotPrice = DepotPriceByClass[vehicleClass]
        if not Player.removeMoney(depotPayment, depotPrice) then
            utils.notify(source, 'You don\'t have money to pay the depot fee', 'error')
            return
        end
    end

    local spanCoords = getSpawnLocation(garageData)

    if not spanCoords then
        return utils.notify(source, 'There is no available space to retrieve the vehicle from the garage.', 'error')
    end

    local vehEntity = CreateVehicleServerSetter(model, vehicleType, spanCoords.x, spanCoords.y, spanCoords.z, spanCoords.w)

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
            'logs'
        },
        filter = {
            plate = plate
        }
    })

    local vState = Entity(vehEntity).state
    vState:set('owner', vehicleData.owner_name, true)
    vState:set('label', vehicleData.label, true)
    vState:set('plate', utils.string.trim(vehicleData.plate), true)
    vState:set('owner_identifier', vehicleData.identifier, true)

    local logs = json.decode(vehicleData.logs)
    local props, deformation = json.decode(vehicleData.properties), json.decode(vehicleData.deformation)
    local netId = NetworkGetNetworkIdFromEntity(vehEntity)

    TriggerClientEvent('vehiclekeys:client:SetOwner', source, plate)
    
    if props then
        vState:set('ox_lib:setVehicleProperties', props, true)
    end

    insertLogs(logs, {
        whodo = Player.name,
        status = 'Take Out',
        date = os.date("%d-%m-%Y %H:%M:%S"),
        garage = logGarage
    })

    local success = storage.updateVehicle({
        filter = {
            plate = utils.string.trim(props.plate)
        },
        update = {
            state = 0,
            logs = json.encode(logs)
        }
    })

    if not success then
        DeleteEntity(vehEntity)
        error('Failed to update database')
    end

    return netId, props.fuelLevel, deformation
end)