if not Framework.qb() then return end

local Utils = require "modules.utils"
local qb = exports['qb-core']:GetCoreObject()

Framework.server = {
    removeMoney = function (source, type, amount)
        local ply = qb.Functions.GetPlayer(source)
        if ply and ply ~= nil then
            return ply.Functions.RemoveMoney(type:lower(), amount, '')
        end
        return false
    end,
    getIdentifier = function (source)
        local Player = qb.Functions.GetPlayer(source)
        if not Player then return end
        return Player.PlayerData.citizenid
    end,
    getName = function (source)
        local Player = qb.Functions.GetPlayer(source)
        if not Player then return end
        return ("%s %s"):format(Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname)
    end,
    GetPlayerFromCitizenid = qb.Functions.GetPlayerByCitizenId,
}

--- check house owner
lib.callback.register('rhd_garage:cb_server:getOwnedHouse', function(src, house)
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

lib.callback.register('rhd_garage:cb_server:getvehdataForPhone', function(src, phoneType)
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
            local EntityExist = lib.callback.await('rhd_garage:cb_client:cekEntityVeh', src, plate)
            local inPoliceImpound, inInsurance = false, false
            local body = mods.bodyHealth and math.floor(mods.bodyHealth) or 100
            local engine = mods.engineHealth and math.floor(mods.engineHealth) or 100
            if VehicleData and next(VehicleData) then
                if db.garage ~= nil then
                    if GarageZone[db.garage] ~= nil then
                        if db.state ~= 0 and db.state ~= 2 then
                            VehicleGarage = db.garage
                            local L = GarageZone[db.garage]?.zones.points
                            if L and #L > 1 then
                                for loc=1, #L do
                                    garageLocation = L[loc].xyz
                                end
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
    end
    return Vehicles
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    TriggerClientEvent("rhd_garage:client:loadedZone", Player.PlayerData.source, GarageZone)
end)