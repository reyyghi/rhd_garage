if not Framework.qb() then return end
Framework.server = {}

local qb = exports['qb-core']:GetCoreObject()


local outVeh = {}

CreateThread(function()
    if GlobalState.veh == nil then
        GlobalState.veh = {}
    end
end)

Framework.server.GetVehOwnerName = function ( plate )
    local owner = MySQL.single.await('SELECT charinfo FROM `players` LEFT JOIN `player_vehicles` ON players.citizenid = player_vehicles.citizenid WHERE plate = ?', {plate})
    if not owner then return false end
    local info = json.decode(owner.charinfo)
    return info.firstname .. ' ' .. info.lastname
end

lib.callback.register('rhd_garage:cb:getVehicleList', function(src, garage)
    local veh = {}
    local cid = qb.Functions.GetPlayer(src).PlayerData.citizenid

    local data = MySQL.query.await('SELECT vehicle, mods, state FROM player_vehicles WHERE garage = ? and citizenid = ?', { garage, cid })
    
    if Config.Garages[garage] and Config.Garages[garage]['impound'] then
        data = MySQL.query.await('SELECT vehicle, mods, state FROM player_vehicles WHERE state = ? and citizenid = ?', { 0, cid })
    end

    if data[1] then
        for i=1, #data do
            local vehicles = json.decode(data[i].mods)
            veh[#veh+1] = {
                vehicle = vehicles,
                state = data[i].state,
                model = data[i].vehicle
            }
        end
    end

    if veh[1] == nil then return false end

    return veh
end)

lib.callback.register('rhd_garage:cb:getVehOwner', function (src, plate)
    local cid = qb.Functions.GetPlayer(src).PlayerData.citizenid
    local vehicle = MySQL.single.await('SELECT balance FROM player_vehicles WHERE citizenid = ? and plate = ? LIMIT 1', { cid, plate })
     
    if not vehicle then return false end
     return true, vehicle.balance
end)

lib.callback.register('rhd_garage:cb:getVehOwnerName', function(_, plate)
    local data = MySQL.single.await('SELECT vehicle FROM player_vehicles WHERE plate = ? LIMIT 1', { plate })
    local fullname = Framework.server.GetVehOwnerName(plate)
    return fullname, data.vehicle
end)

--Call from qb-phone
lib.callback.register('rhd_garage:cb:getDataVehicle', function(src)
    local cid = qb.Functions.GetPlayer(src).PlayerData.citizenid
    local Vehicles = {}

    local result = MySQL.query.await('SELECT * FROM player_vehicles WHERE citizenid = ?', { cid })
    if result[1] then
        for i=1, #result do
            local db = result[i]
            local VehicleData = qb.Shared.Vehicles[db.vehicle]
            local mods = json.decode(db.mods)

            local VehicleGarage = 'None'
            
            local EntityExist = lib.callback.await('rhd_garage:cb:cekEntity', src, db.plate)

            if db.garage ~= nil then
                if Config.Garages[db.garage] ~= nil then
                    if db.state ~= 0 and db.state ~= 2 then
                        VehicleGarage = db.garage
                    end
                else
                    if db.state == 1 then
                        VehicleGarage = 'House Garages'
                    end
                end
            end

            if db.state == 0 then
                
                db.state = locale('rhd_garage:phone_veh_out_garage')

                if not EntityExist then
                    db.state = locale('rhd_garage:phone_veh_in_impound')
                end
                
            elseif db.state == 1 then
                db.state = locale('rhd_garage:phone_veh_in_garage')
            elseif db.state == 2 then
                db.state = locale('rhd_garage:phone_veh_in_policeimpound')
            end

            local fullname
            if VehicleData["brand"] ~= nil then
                fullname = VehicleData["brand"] .. " " .. VehicleData["name"]
            else
                fullname = VehicleData["name"]
            end

            local body = math.ceil(mods.bodyHealth)
            local engine = math.ceil(mods.engineHealth)

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
                body = body
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
    if update then
        outVeh[plate] = vehicle
        GlobalState.veh = outVeh
    end
end)
