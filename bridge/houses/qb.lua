local psHousing = GetResourceState("ps-housing") ~= "missing"
local qbHousing = GetResourceState("qb-houses") ~= "missing"
local isServer = IsDuplicityVersion()

local lasthouse = nil
local houseZone = {}


--- for qb-houses or ps-housing
if qbHousing or psHousing then
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
                                    radFunc.create({
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
                    
                                    radFunc.create({
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
        
                                    utils.drawtext('show', label:upper(), 'warehouse')
                                end
                            end, house)
                        end,
                        onExit = function ()
                            utils.drawtext('hide')
                            radFunc.remove("open_garage")
                            radFunc.remove("store_veh")
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
    
    if psHousing then
        RegisterNetEvent('qb-garages:client:removeHouseGarage', function(house)
            Config.HouseGarages[house] = nil
        end)
    end
    
    if isServer then
        --- check house owner
        lib.callback.register('rhd_garage:cb_server:getOwnedHouse', function(src, house)
            local key = false
            local player = fw.gp(src)
            local license = player.license
            local cid = player.citizenid
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
    
    
        AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
            GlobalState.rhd_garage_zone = GarageZone
        end)
    end
end