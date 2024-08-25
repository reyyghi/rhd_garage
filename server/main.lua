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

