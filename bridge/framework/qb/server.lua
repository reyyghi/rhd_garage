if not Framework.qb() then return end
Framework.server = {}

local Utils = require "modules.utils"
local qb = exports['qb-core']:GetCoreObject()

Framework.server.GetPlayer = qb.Functions.GetPlayer

Framework.server.removeMoney = function (source, type, amount)
    local ply = qb.Functions.GetPlayer(source)
    if string.lower(type) == 'cash' then
        type = 'cash'
    elseif string.lower(type) == 'bank' then
        type = 'bank'
    else
        return false
    end
    if ply and ply ~= nil then
        ply.Functions.RemoveMoney(type, amount, '')
        return true
    end
    return false
end

lib.callback.register('rhd_garage:cb:getVehicleList', function(src, garage, impound, shared)
    local veh = {}
    local cid = qb.Functions.GetPlayer(src).PlayerData.citizenid
    local impound_garage = impound
    local shared_garage = shared

    local data = MySQL.query.await('SELECT vehicle, mods, state, plate, fakeplate FROM player_vehicles WHERE garage = ? and citizenid = ?', { garage, cid })
    
    if impound_garage then
        if shared_garage then return false end
        data = MySQL.query.await('SELECT vehicle, mods, state, plate, fakeplate FROM player_vehicles WHERE state = ? and citizenid = ?', { 0, cid })
    end

    if shared_garage then
        if impound_garage then return false end
        data = MySQL.query.await('SELECT player_vehicles.vehicle, player_vehicles.mods, player_vehicles.state, player_vehicles.plate, player_vehicles.fakeplate, players.charinfo FROM player_vehicles LEFT JOIN players ON players.citizenid = player_vehicles.citizenid WHERE player_vehicles.garage = ?', { garage })
    end

    if data[1] then
        for i=1, #data do
            local vehicles = json.decode(data[i].mods)
            local name = data[i].charinfo and ("%s %s"):format(json.decode(data[i].charinfo).firstname, json.decode(data[i].charinfo).lastname)
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
    local vehicle = MySQL.single.await('SELECT balance FROM player_vehicles WHERE citizenid = ? AND plate = ? OR fakeplate = ? LIMIT 1', { cid, plate })

    if shared then
        vehicle = MySQL.single.await('SELECT balance FROM player_vehicles WHERE plate = ? OR fakeplate = ? LIMIT 1', { plate })
    end
     
    if not vehicle then 
        return false, nil
    end

    return true, vehicle and vehicle.balance
end)

lib.callback.register('rhd_garage:cb:getVehOwnerName', function(_, plate)
    local data = MySQL.single.await('SELECT player_vehicles.vehicle, players.charinfo FROM player_vehicles LEFT JOIN players ON players.citizenid = player_vehicles.citizenid WHERE plate = ? OR fakeplate = ? LIMIT 1', { plate })

    local fullname = data.charinfo and ("%s %s"):format(json.decode(data.charinfo).firstname, json.decode(data.charinfo).lastname)
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
            local plate = db.plate:trim()
            local VehicleGarage = 'None'
            local garageLocation = nil
            local EntityExist = lib.callback.await('rhd_garage:cb:cekEntity', src, plate)
            local inPoliceImpound, inInsurance = false, false
            
            local body = math.ceil(mods.bodyHealth)
            local engine = math.ceil(mods.engineHealth)

            if db.garage ~= nil then
                if GarageZone[db.garage] ~= nil then
                    if db.state ~= 0 and db.state ~= 2 then
                        VehicleGarage = db.garage

                        local L = GarageZone[db.garage]['location']

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
                fullname = CNV[plate] and CNV[plate].name or fullname,
                brand = VehicleData["brand"],
                model = VehicleData["name"],
                plate = plate,
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

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    TriggerClientEvent("rhd_garage:client:loadedZone", Player.PlayerData.source, GarageZone)
end)