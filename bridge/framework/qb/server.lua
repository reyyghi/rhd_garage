if not Framework.qb() then return end
Framework.server = {}

local qb = exports['qb-core']:GetCoreObject()

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

Framework.server.updatePlateOutsideVehicle = function (curPlate, newPlate)
    local cP = Framework.server.GetVehPlate(curPlate)
    local nP = Framework.server.GetVehPlate(newPlate)
    local veh = outVeh[cP]
    
    outVeh[nP] = veh
    GlobalState.veh = outVeh
end exports('updatePlateOutsideVehicle', Framework.server.updatePlateOutsideVehicle)

Framework.server.GetVehOwnerName = function ( plate )
    local plate = Framework.server.GetVehPlate(plate)
    local owner = MySQL.single.await('SELECT charinfo FROM `players` LEFT JOIN `player_vehicles` ON players.citizenid = player_vehicles.citizenid WHERE plate = ?', {plate})
    
    if not owner then 
        owner = MySQL.single.await('SELECT charinfo FROM `players` LEFT JOIN `player_vehicles` ON players.citizenid = player_vehicles.citizenid WHERE fakeplate = ?', {plate})
    end

    if not owner then return false end
    local info = json.decode(owner.charinfo)
    return info.firstname .. ' ' .. info.lastname
end

lib.callback.register('rhd_garage:cb:getVehicleList', function(src, garage)
    local veh = {}
    local cid = qb.Functions.GetPlayer(src).PlayerData.citizenid
    local impound_garage = Config.Garages[garage] and Config.Garages[garage]['impound']
    local shared_garage = Config.Garages[garage] and Config.Garages[garage]['shared']

    local data = MySQL.query.await('SELECT vehicle, mods, state, plate, fakeplate FROM player_vehicles WHERE garage = ? and citizenid = ?', { garage, cid })
    
    if impound_garage then
        if shared_garage then return false end
        data = MySQL.query.await('SELECT vehicle, mods, state, plate, fakeplate FROM player_vehicles WHERE state = ? and citizenid = ?', { 0, cid })
    end

    if shared_garage then
        if impound_garage then return false end
        data = MySQL.query.await('SELECT vehicle, mods, state, plate, fakeplate FROM player_vehicles WHERE garage = ?', { garage })
    end

    if data[1] then
        for i=1, #data do
            local vehicles = json.decode(data[i].mods)
            local name = Framework.server.GetVehOwnerName(vehicles.plate)
            local state = data[i].state
            local model = data[i].vehicle
            local plate = data[i].plate
            local fakeplate = data[i].fakeplate

            veh[#veh+1] = {
                vehicle = vehicles,
                state = state,
                model = model,
                plate = plate,
                fakeplate = fakeplate,
                owner = name
            }
        end
    end

    if veh[1] == nil then return false end

    return veh
end)

lib.callback.register('rhd_garage:cb:getVehOwner', function (src, plate, shared)
    local cid = qb.Functions.GetPlayer(src).PlayerData.citizenid
    local vehicle = MySQL.single.await('SELECT balance FROM player_vehicles WHERE citizenid = ? and plate = ? LIMIT 1', { cid, plate })

    if shared then
        vehicle = MySQL.single.await('SELECT balance FROM player_vehicles WHERE plate = ? LIMIT 1', { plate })
    end
     
    if not vehicle then 
       vehicle = MySQL.single.await('SELECT balance FROM player_vehicles WHERE citizenid = ? and fakeplate = ? LIMIT 1', { cid, plate })
    end

    return true, vehicle.balance
end)

lib.callback.register('rhd_garage:cb:getVehOwnerName', function(_, plate)
    local data = MySQL.single.await('SELECT vehicle FROM player_vehicles WHERE plate = ? LIMIT 1', { plate })

    if not data then 
        data = MySQL.single.await('SELECT vehicle FROM player_vehicles WHERE fakeplate = ? LIMIT 1', { plate })
    end

    local fullname = Framework.server.GetVehOwnerName(plate)
    if not data then return false end
    return fullname, data.vehicle
end)

--- check house owner
lib.callback.register('rhd_garage:getOwnedHouse', function(src, house)
    local key = false
    local player = qb.Functions.GetPlayer(src)
    local license = player.PlayerData.license
    local cid = player.PlayerData.citizenid
    local houseKey = false
    
    if GetResourceState("qb-houses") ~= "missing" then
        houseKey = exports['qb-houses']:hasKey(license, cid, house)
    elseif GetResourceState("ps-housing") ~= "missing" then
        houseKey = exports['ps-housing']:IsOwner(src, house)
    end

    if houseKey then key = not key end
    return key
end)

--- Call from qb-phone
RegisterNetEvent('rhd_garage:server:houseGarageConfig', function(data)
    Config.HouseGarages = data
end)

RegisterNetEvent('rhd_garage:server:addHouseGarage', function(house, garageInfo)
    Config.HouseGarages[house] = garageInfo
end)

lib.callback.register('rhd_garage:cb:getDataVehicle', function(src, phoneType)
    local cid = qb.Functions.GetPlayer(src).PlayerData.citizenid
    local Vehicles = {}

    local result = MySQL.query.await('SELECT * FROM player_vehicles WHERE citizenid = ?', { cid })
    if result[1] then
        for i=1, #result do
            local db = result[i]
            local VehicleData = qb.Shared.Vehicles[db.vehicle]
            local mods = json.decode(db.mods)
            local VehicleGarage = 'None'
            local garageLocation = nil
            local EntityExist = lib.callback.await('rhd_garage:cb:cekEntity', src, db.plate)
            local inPoliceImpound, inInsurance = false, false
            
            local body = math.ceil(mods.bodyHealth)
            local engine = math.ceil(mods.engineHealth)

            if db.garage ~= nil then
                if Config.Garages[db.garage] ~= nil then
                    if db.state ~= 0 and db.state ~= 2 then
                        VehicleGarage = db.garage

                        local L = Config.Garages[db.garage]['location']

                        if type(L) == 'table' then
                            for loc=1, #L do
                                garageLocation = L[loc].xyz
                            end
                        elseif type(L) == 'vector4' then
                            garageLocation = L
                        end
                    end
                    
                else
                    if db.state == 1 then
                        local HouseGarage = Config.HouseGarages

                        for k, v in pairs(HouseGarage) do
                            
                            if v.label == db.garage then
                                VehicleGarage = db.garage
                                
                                local L = v.takeVehicle
    
                                garageLocation = vec3(L.x, L.y, L.z)
                            end
                        end
                    end
                end
            end

            if db.state == 0 then
                
                db.state = locale('rhd_garage:phone_veh_out_garage')

                if not EntityExist then
                    db.state = locale('rhd_garage:phone_veh_in_impound')

                    inInsurance = true
                end
            elseif db.state == 1 then
                db.state = locale('rhd_garage:phone_veh_in_garage')

            elseif db.state == 2 then
                db.state = locale('rhd_garage:phone_veh_in_policeimpound')

                inPoliceImpound = true
            end

            local fullname
            if VehicleData["brand"] ~= nil then
                fullname = VehicleData["brand"] .. " " .. VehicleData["name"]
            else
                fullname = VehicleData["name"]
            end

            if body > 1000 then
                body = 1000
            end
            if engine > 1000 then
                engine = 1000
            end

            Vehicles[#Vehicles+1] = {
                fullname = fullname,
                brand = VehicleData["brand"],
                model = VehicleData["name"],
                plate = db.plate,
                garage = VehicleGarage,
                state = db.state,
                fuel = mods.fuelLevel,
                engine = engine,
                body = body,
                paymentsleft = db.paymentsleft,
                garageLocation = json.encode(garageLocation),
                inInsurance = inInsurance,
                inPoliceImpound = inPoliceImpound
            }
            
        end
    end
    return Vehicles
end)

lib.callback.register('rhd_garage:cb:removeMoney', function(src, type, amount)
    local success = false
    local ply = qb.Functions.GetPlayer(source)
    if type == 'cash' then
        ply.Functions.RemoveMoney('cash', amount)
        success = not success
    elseif type == 'bank' then
        ply.Functions.RemoveMoney('bank', amount)
        success = not success
    end
    return success
end)

RegisterNetEvent('rhd_garage:removeMoney', function ( type, amount )
    local ply = qb.Functions.GetPlayer(source)
    if type == 'cash' then
        ply.Functions.RemoveMoney('cash', amount)
    elseif type == 'bank' then
        ply.Functions.RemoveMoney('bank', amount)
    end
end)

RegisterNetEvent('rhd_garage:server:updateVehState', function ( data )
    local prop = data.prop
    local state = data.state
    local vehicle = data.vehicle
    local garage = data.garage
    local plate = data.plate
    local update = MySQL.update.await('UPDATE player_vehicles SET state = ?, mods = ?, garage = ? WHERE plate = ?', { state, json.encode(prop), garage, plate })

    if update == 0 then 
        update = MySQL.update.await('UPDATE player_vehicles SET state = ?, mods = ?, garage = ? WHERE fakeplate = ?', { state, json.encode(prop), garage, plate })
    end

    if update == 1 then
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
