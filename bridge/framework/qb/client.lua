if not Framework.qb() then return end

local qb = exports['qb-core']:GetCoreObject()

local Utils = require "modules.utils"
local lasthouse = nil
local houseZone = {}

Framework.playerJob = function ()
    return qb.Functions.GetPlayerData().job
end

Framework.playerGang = function ()
    return qb.Functions.GetPlayerData().gang
end

Framework.playerName = function ()
    return qb.Functions.GetPlayerData().charinfo.firstname .. ' ' .. qb.Functions.GetPlayerData().charinfo.lastname
end

Framework.getVehName = function ( model )
    local vehname =  qb.Shared.Vehicles[model] and qb.Shared.Vehicles[model].name or 'Vehicle Not Found'
    return vehname
end

Framework.getMoney = function ( type )
    local amount = 0
    local plyMoney = qb.Functions.GetPlayerData().money

    if type == 'cash' then
        amount = plyMoney['cash']
    elseif type == 'bank' then
        amount = plyMoney['bank']
    end

    return amount
end

--- for qb-vehiclesales
exports('isPlyVeh', function ( plate, cb )
    local plyVeh, balance = lib.callback.await('rhd_garage:cb:getVehOwner', false, plate:trim(), false)
    if cb then cb(plyVeh, balance) else return plyVeh, balance end
end)

--- for qb-phone
lib.callback.register('rhd_garage:cb:cekEntity', function (plate)
    if Utils.getoutsidevehicleByPlate(plate:trim()) then
        return true
    end
    return false
end)

exports('trackOutVeh', function (plate)
   return Utils.trackOutVeh( plate:trim() )
end)

exports('getDataVehicle', function ()
    return lib.callback.await('rhd_garage:cb:getDataVehicle', false)
end)

--- for qb-houses or ps-housing
RegisterNetEvent('qb-garages:client:setHouseGarage', function(house, hasKey)
    if Config.HouseGarages[house] then
        if lasthouse ~= house then
            if lasthouse then
                houseZone[lasthouse]:remove()
            end
            if hasKey and Config.HouseGarages[house].takeVehicle.x then
                local coords = Config.HouseGarages[house].takeVehicle
                local label = Config.HouseGarages[house].label
                local vec4 = vec4(coords.x, coords.y, coords.z, coords.w)
                local vec3 = vec3(coords.x, coords.y, coords.z)
                houseZone[house] = lib.zones.sphere({
                    coords = vec3,
                    onEnter = function ()
                        lib.callback('rhd_garage:getOwnedHouse', false, function (key)
                            if key then
                                Utils.createRadial({
                                    id = "open_garage",
                                    label = locale("rhd_garage:open_garage"),
                                    icon = "warehouse",
                                    event = "rhd_garage:radial:open",
                                    action = function ()
                                        if not cache.vehicle then
                                            Garage.openMenu( {garage = label, impound = false, shared = false} )
                                        end
                                    end
                                })
                
                                Utils.createRadial({
                                    id = "store_veh",
                                    label = locale("rhd_garage:store_vehicle"),
                                    icon = "parking",
                                    event = "rhd_garage:radial:store",
                                    action = function ()
                                        local vehicle = cache.vehicle
                                        if not vehicle then
                                            vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped))
                                        end
                        
                                        if not Utils.classCheck( "car", vehicle ) then return Utils.notify(locale('rhd_garage:invalid_vehicle_class', label:lower())) end
                        
                                        if DoesEntityExist(vehicle) then
                                            if cache.vehicle then
                                                if cache.seat ~= -1 then return end
                                                TaskLeaveAnyVehicle(cache.ped, true, 0)
                                                Wait(1000)
                                            end
                                            Garage.storeVeh({
                                                vehicle = vehicle,
                                                garage = label,
                                            })
                                        else
                                            Utils.notify(locale('rhd_garage:not_vehicle_exist'), 'error')
                                        end
                                    end
                                })
    
                                Utils.drawtext('show', label:upper(), 'warehouse')
                            end
                        end, house)
                    end,
                    onExit = function ()
                        Utils.drawtext('hide')
                        Utils.removeRadial("open_garage")
                        Utils.removeRadial("store_veh")
                    end
                })
                lasthouse = house
            end
        end
    end
end)

RegisterNetEvent('qb-garages:client:houseGarageConfig', function(garageConfig)
    Config.HouseGarages = garageConfig
    TriggerServerEvent('rhd_garage:server:houseGarageConfig', Config.HouseGarages)
end)

RegisterNetEvent('qb-garages:client:addHouseGarage', function(house, garageInfo)
    Config.HouseGarages[house] = garageInfo
    TriggerServerEvent('rhd_garage:server:addHouseGarage', house, garageInfo)
end)

if GetResourceState("ps-housing") ~= "missing" then
    RegisterNetEvent('qb-garages:client:removeHouseGarage', function(house)
        Config.HouseGarages[house] = nil
    end)
end