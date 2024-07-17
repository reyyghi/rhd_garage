local psHousing = GetResourceState("ps-housing") ~= "missing"
local qbHousing = GetResourceState("qb-houses") ~= "missing"
local isServer = IsDuplicityVersion()

local lasthouse = nil
local houseZone = {}
local isOwner = false


--- for qb-houses or ps-housing
if qbHousing or psHousing then
    RegisterNetEvent('qb-garages:client:setHouseGarage', function(house, hasKey)
        local HG = Config.HouseGarages[house]
        if not HG then return end
        if lasthouse == house then return end
        
        if lasthouse then
            houseZone[lasthouse]:remove()
        end
        
        if hasKey and HG.takeVehicle?.x then
            local coords = HG.takeVehicle
            local label = HG.label
            local spawnloc = vec4(coords.x, coords.y, coords.z, coords.w)
            houseZone[house] = lib.zones.sphere({
                coords = spawnloc.xyz,
                inside = function ()
                    if IsControlJustPressed(0, 38) and isOwner then
    
                        local args = {
                            garage = label,
                            type = {'car', 'motorcycle', 'cycles'},
                            spawnpoint = spawnloc
                        }
    
                        if cache.vehicle then
                            return exports.rhd_garage:storeVehicle(args)
                        end
    
                        exports.rhd_garage:openMenu(args)
                    end
                end,
                onEnter = function ()
                    isOwner = lib.callback.await('rhd_garage:cb_server:getOwnedHouse', false, house)
                    if not isOwner then return end
                    local dl = ('[E] - %s'):format(label)
                    utils.drawtext('show', dl:upper(), 'warehouse')
                end,
                onExit = function ()
                    isOwner = false
                    utils.drawtext('hide')
                end
            })
            lasthouse = house
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
    end
end