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

Framework.getVehName = function ( model )
    return qb.Shared.Vehicles[model] and qb.Shared.Vehicles[model].name or 'Vehicle Not Found'
end

Framework.getName = function()
    local charinfo = qb.Functions.GetPlayerData().charinfo
    return ("%s %s"):format(charinfo.firstname, charinfo.lastname)
end

Framework.getMoney = function ( type )
    return qb.Functions.GetPlayerData().money[type:lower()]
end

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
                        lib.callback('rhd_garage:cb_server:getOwnedHouse', false, function (key)
                            if key then
                                Utils.createRadial({
                                    id = "open_garage",
                                    label = locale("rhd_garage:open_garage"),
                                    icon = "warehouse",
                                    event = "rhd_garage:radial:open",
                                    garage = {
                                        label = label,
                                        impound = false,
                                        shared = false,
                                        type = "car"
                                    }
                                })
                
                                Utils.createRadial({
                                    id = "store_veh",
                                    label = locale("rhd_garage:store_vehicle"),
                                    icon = "parking",
                                    event = "rhd_garage:radial:store",
                                    garage = {
                                        label = label,
                                        impound = false,
                                        shared = false,
                                        type = "car"
                                    }
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