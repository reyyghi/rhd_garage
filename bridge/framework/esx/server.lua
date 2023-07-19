if not Framework.esx() then return end

local esx = exports.es_extended:getSharedObject()

local outVeh = {}

CreateThread(function()
    if GlobalState.veh == nil then
        GlobalState.veh = {}
    end
end)

lib.callback.register('rhd_garage:cb:getVehicleList', function(src, garage)
    local veh = {}
    local identifer = esx.GetPlayerFromId(src).identifier

    local data = MySQL.query.await('SELECT vehicle, stored FROM owned_vehicles WHERE garage = ? and owner = ?', { garage, identifer })
    
    if Config.Garages[garage] and Config.Garages[garage]['impound'] then
        data = MySQL.query.await('SELECT vehicle, stored FROM owned_vehicles WHERE stored = ? and owner = ?', { 0, identifer })
    end

    if data[1] then
        for i=1, #data do
            local vehicles = json.decode(data[i].vehicle)
            veh[#veh+1] = {
                vehicle = vehicles,
                state = data[i].stored
            }
        end
    end

    if veh[1] == nil then return false end

    return veh
end)

lib.callback.register('rhd_garage:cb:getVehOwner', function (src, plate)
    local identifer = esx.GetPlayerFromId(src).identifier
    local vehicle = MySQL.single.await('SELECT `vehicle` FROM `owned_vehicles` WHERE `owner` = ? and plate = ? LIMIT 1', { identifer, plate })
     
    if not vehicle then return false end
     return true
end)

lib.callback.register('rhd_garage:cb:removeMoney', function(src, type, amount)
    local success = false
    local ply = esx.GetPlayerFromId(src)
    if type == 'cash' then
        ply.removeAccountMoney('money', amount)
        success = not success
    elseif type == 'bank' then
        ply.removeAccountMoney('bank', amount)
        success = not success
    end
    return success
end)

RegisterNetEvent('rhd_garage:server:updateVehState', function ( data )
    local prop = data.prop
    local state = data.state
    local vehicle = data.vehicle
    local garage = data.garage
    local plate = data.plate
    local update = MySQL.update.await('UPDATE owned_vehicles SET stored = ?, vehicle = ?, garage = ? WHERE plate = ?', { state, json.encode(prop), garage, plate })
    if update then
        outVeh[plate] = vehicle
        GlobalState.veh = outVeh
    end
end)
