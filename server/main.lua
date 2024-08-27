if not lib.checkDependency('ox_lib', '3.23.1') then error('This resource requires ox_lib version 3.23.1') end

local zones = lib.loadJson('data.garages')

local addonGarage = {}

---@param garageData garageZone
local function registerGarage(garageData)
    assert(not addonGarage[garageData.label], 'A garage with this label '..garageData.label..' already exists.')
    addonGarage[garageData.label] = garageData
    TriggerClientEvent('rhd_garage:client:registerGarage', -1, garageData)
end

exports('AddGarage', registerGarage)

---@param label string
local function removeGarage(label)
    if not addonGarage[label] then
        return
    end
    addonGarage[label] = nil
    TriggerClientEvent('rhd_garage:client:removeGarage', -1, label)
end

exports('RemoveGarage', removeGarage)

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
    if player.removeMoney('bank', data.price) then
        local success = vehStorage.updatePlayerVehicles({
            filter = {
                identifier = player.identifier,
                plate = data.plate
            },
            update = {
                vehicle_name = data.name
            }
        }, 'update')
        return success
    end
    return false
end)

lib.callback.register('rhd_garage:server:getVehicles', function(src, data)
    local player = PLAYERs[src]
    if not player then return end

    local stored = data.impound and 0 or 1
    local identifier = not data.shared and player.identifier

    local vehicles = vehStorage.fetchPlayerVehicles({
        filter = {
            identifier = identifier,
            stored = stored,
            garage = data.garage
        },
        ownerData = data.shared
    }, 'select')

    return vehicles
end)

lib.callback.register('rhd_garage:server:getVehicleLocationByPlate', function (src, plate)
    local vehCoords
    local allvehicles = GetAllVehicles()
    
    lib.array.forEach(allvehicles, function (entity)
        local entityPlate = utils.vehicle.getPlate(entity)
        if entityPlate == plate then
            vehCoords = GetEntityCoords(entity)
        end
    end)

    if not vehCoords then
        local garage = vehStorage.getGarageByPlate(plate)
        local notifyText = 'Your vehicle is in the ' .. garage

        if garage == 'impounded' then
            notifyText = 'Your vehicle is at the depot'
        end
        
        utils.notify(src, notifyText)
        return false
    end

    return vehCoords
end)

lib.callback.register('rhd_garage:server:SaveVehicle', function(src, saveData)
    local player = PLAYERs[src]
    if not player then return end


    local mods = saveData.props
    local deformation = saveData.deformation or {}

    local netId = saveData.netId
    local garage = saveData.garage
    local plate = utils.string.trim(mods.plate --[[@as string]])

    local sharedGarage = false
    lib.array.forEach(zones, function (data)
        if data.label == garage and data.type == 'shared' then
            sharedGarage = true
            return
        end
    end)

    local identifier = not sharedGarage and player.identifier

    local vehicle = NetworkGetEntityFromNetworkId(netId)

    local vehicles = vehStorage.fetchPlayerVehicles({
        filter = {
            identifier = identifier,
            plate = plate --[[@as string]]
        },
    }, 'select')

    if vehicles then
        local success = vehStorage.updatePlayerVehicles({
            update = {
                vehicle = json.encode(mods),
                stored = 1,
                garage = garage,
                fuel = mods.fuelLevel --[[@as number]],
                engine = mods.engineHealth --[[@as number]],
                body = mods.bodyHealth --[[@as number]],
                deformation = json.encode(deformation)
            },
            filter = {
                identifier = identifier,
                plate = plate,
            }
        }, 'update')

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
    local impound = spawnData.impound
    local vehicleType = spawnData.class

    local Player = PLAYERs[source]
    if not Player then return end

    if impound then
        if not Player.removeMoney('bank', impound) then
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

    local props, deformation = vehStorage.getProperties(plate)
    local netId = NetworkGetNetworkIdFromEntity(vehEntity)

    TriggerClientEvent('vehiclekeys:client:SetOwner', source, plate)
    
    if props then
        Entity(vehEntity).state:set('ox_lib:setVehicleProperties', props, true)
    end

   local success = vehStorage.updatePlayerVehicles({
        filter = {
            plate = utils.string.trim(props.plate)
        },
        update = {
            stored = 0
        }
    }, 'update')

    if not success then
        DeleteEntity(vehEntity)
        error('Failed to update database')
    end

    return netId, props.fuelLevel, deformation
end)

-- RegisterCommand('addgarage', function (source)
--     registerGarage({
--         label = 'Test Aja',
--         type = 'default',
--         class = {'car', 'motorcycle'},
--         canAccess = function (data)
--             return true
--         end,
--         blip = {
--             label = "Parkiran Hafizh",
--             sprite = 357,
--             colour = 7
--         },
--         points = {
--             take = vec(294.3668, -346.2071, 44.9199, 72.5447),
--             save  = vec(296.0357, -343.1743, 44.9199, 79.6206),
--             useMarker = true
--         }

--     })
-- end, false)

-- RegisterCommand('removeGarage', function ()
--     removeGarage('Test Aja')
-- end, false)