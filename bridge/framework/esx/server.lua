if not Framework.esx() then return end
Framework.server = {}

local esx = exports.es_extended:getSharedObject()

local outVeh = {}

CreateThread(function()
    if GlobalState.veh == nil then
        GlobalState.veh = {}
    end
end)

Framework.server.GetVehPlate = function ( number )
    if not number then return nil end
    return (string.gsub(number, '^%s*(.-)%s*$', '%1'))
end

Framework.server.GetVehOwnerName = function ( plate )
    local plate = Framework.server.GetVehPlate(plate)
    local owner = MySQL.single.await('SELECT firstname, lastname FROM `users` LEFT JOIN `owned_vehicles` ON users.identifier = owned_vehicles.owner WHERE plate = ?', {plate})
    if not owner then return false end
    return owner.firstname .. ' ' .. owner.lastname
end

lib.callback.register('rhd_garage:cb:getVehicleList', function(src, garage)
    local veh = {}
    local identifier = esx.GetPlayerFromId(src).identifier
    local impound_garage = Config.Garages[garage] and Config.Garages[garage]['impound']
    local shared_garage = Config.Garages[garage] and Config.Garages[garage]['shared']

    local data = MySQL.query.await('SELECT vehicle, stored FROM owned_vehicles WHERE garage = ? and owner = ?', { garage, identifier })
    
    if impound_garage then
        if shared_garage then return false end
        data = MySQL.query.await('SELECT vehicle, stored FROM owned_vehicles WHERE stored = ? and owner = ?', { 0, identifier })
    end
    
    if shared_garage then
        if impound_garage then return false end
        data = MySQL.query.await('SELECT vehicle, stored FROM owned_vehicles WHERE garage = ?', { garage })
    end

    if data[1] then
        for i=1, #data do
            local vehicles = json.decode(data[i].vehicle)
            local name = Framework.server.GetVehOwnerName(vehicles.plate)
            veh[#veh+1] = {
                vehicle = vehicles,
                state = data[i].stored,
                owner = name
            }
        end
    end

    if veh[1] == nil then return false end

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
    local data = MySQL.single.await('SELECT vehicle FROM owned_vehicles WHERE plate = ? LIMIT 1', { plate })
    local vehicle = json.decode(data.vehicle)
    local fullname = Framework.server.GetVehOwnerName(plate)
    return fullname, vehicle.model
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

CreateThread(function ()
    local resource = GetInvokingResource() or GetCurrentResourceName()

    local currentVersion = GetResourceMetadata(resource, 'version', 0)

    if currentVersion then
        currentVersion = currentVersion:match('%d+%.%d+%.%d+')
    end

    if not currentVersion then return print(("^1Unable to determine current resource version for '%s' ^0"):format(resource)) end

    SetTimeout(1000, function()
        PerformHttpRequest('https://api.github.com/repos/reyyghi/rhd_garage/releases/latest', function(status, response)
            if status ~= 200 then return end

            response = json.decode(response)
            if response.prerelease then return end

            local latestVersion = response.tag_name:match('%d+%.%d+%.%d+')
            if not latestVersion or latestVersion == currentVersion then return end

            local cv = { string.strsplit('.', currentVersion) }
            local lv = { string.strsplit('.', latestVersion) }

            for i = 1, #cv do
                local current, minimum = tonumber(cv[i]), tonumber(lv[i])

                if current ~= minimum then
                    if current < minimum then
                        return print(('^3An update is available for %s (current version: %s)\r\n%s^0'):format(resource, currentVersion, response.html_url))
                    else break end
                end
            end
        end, 'GET')
    end)
end)
