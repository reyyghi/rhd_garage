if not Framework.esx() then return end
Framework.server = {}

local esx = exports.es_extended:getSharedObject()

Framework.server.GetPlayer = esx.GetPlayerFromId

Framework.server.removeMoney = function (source, type, amount)
    local ply = esx.GetPlayerFromId(source)
    if string.lower(type) == 'cash' then
        type = 'money'
    elseif string.lower(type) == 'bank' then
        type = 'bank'
    else
        return false
    end
    if ply and ply ~= nil then
        ply.removeAccountMoney(type, amount, '')
        return true
    end
    return false
end

lib.callback.register('rhd_garage:cb:getVehicleList', function(src, garage, impound, shared)
    local veh = {}
    local identifier = esx.GetPlayerFromId(src).identifier
    local impound_garage = impound
    local shared_garage = shared

    local data = MySQL.query.await('SELECT vehicle, plate, stored FROM owned_vehicles WHERE garage = ? and owner = ?', { garage, identifier })
    
    if impound_garage then
        if shared_garage then return false end
        data = MySQL.query.await('SELECT vehicle, plate, stored FROM owned_vehicles WHERE stored = ? and owner = ?', { 0, identifier })
    end
    
    if shared_garage then
        if impound_garage then return false end
        data = MySQL.query.await('SELECT owned_vehicles.vehicle, owned_vehicles.plate, owned_vehicles.stored, users.firstname, users.lastname FROM owned_vehicles LEFT JOIN users ON users.identifier = owned_vehicles.owner WHERE owned_vehicles.garage = ?', { garage }) 
    end

    if data[1] then
        for i=1, #data do
            local vehicles = json.decode(data[i].vehicle)
            local name = ("%s %s"):format(data[i].firstname, data[i].lastname)
            local plate = data[i].plate
            veh[#veh+1] = {
                vehicle = vehicles,
                state = data[i].stored,
                owner = name,
                plate = plate
            }
        end
    end

    return veh
end)

lib.callback.register('rhd_garage:cb:getVehOwner', function (src, plate, shared)
    local identifier = esx.GetPlayerFromId(src).identifier
    local vehicle = MySQL.single.await('SELECT `vehicle` FROM `owned_vehicles` WHERE `owner` = ? and plate = ? LIMIT 1', { identifier, plate })
    
    if shared then
        vehicle = MySQL.single.await('SELECT vehicle FROM owned_vehicles WHERE plate = ? LIMIT 1', { plate })
    end 

    if not vehicle then return false end
     return true
end)

lib.callback.register('rhd_garage:cb:getVehOwnerName', function(_, plate)
    local data = MySQL.single.await('SELECT owned_vehicles.vehicle, users.firstname, users.lastname FROM owned_vehicles LEFT JOIN users ON users.identifier = owned_vehicles.owner WHERE owned_vehicles.plate = ? LIMIT 1', { plate })
    if not data then return false end
    local vehicle = json.decode(data.vehicle)
    local fullname = ("%s %s"):format(data.firstname, data.lastname)
    return fullname, vehicle.model
end)

RegisterNetEvent('esx:playerLoaded', function(player, xPlayer, isNew)
    TriggerClientEvent("rhd_garage:client:loadedZone", xPlayer.source, GarageZone)
end)