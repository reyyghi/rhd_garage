if not lib.checkDependency('ox_lib', '3.23.1') then error('This resource requires ox_lib version 3.23.1') end

local zones = lib.loadJson('data.garages')

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

lib.callback.register('rhd_garage:server:SpawnVehicle', function(source, spawnData)
    local ped = GetPlayerPed(source)
    local entityOwner = NetworkGetEntityOwner(ped)
    local coords = spawnData.coords
    local warp = spawnData.warp
    local model = spawnData.model
    local plate = spawnData.plate

    local vehEntity = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, true, false)

    Wait(100)
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
        TriggerClientEvent('ox_lib:setVehicleProperties', entityOwner, netId, props)
    end

    return netId, deformation
end)