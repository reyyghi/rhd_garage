if not Framework.qb() then return end

local qb = exports['qb-core']:GetCoreObject()

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
    return qb.Shared.Vehicles[model].name
end

Framework.isPlyVeh = function ( plate, cb)
    local plyVeh, balance = lib.callback.await('rhd_garage:cb:getVehOwner', false, plate)
    if cb then cb(plyVeh, balance) else return plyVeh, balance end
end

Framework.getdbVehicle = function ( garage )
    local dataVeh = lib.callback.await('rhd_garage:cb:getVehicleList', false, garage)
    return dataVeh
end

Framework.updateState = function ( data )
    TriggerServerEvent('rhd_garage:server:updateVehState', data)
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

Framework.removeMoney = function ( type, amount )
    return lib.callback.await('rhd_garage:cb:removeMoney', false, type, amount)
end


--- for qb-vehiclesales
exports('isPlyVeh', function ( plate, cb )
    return Framework.isPlyVeh( plate, cb)
end)

--- for qb-phone
exports('getDataVehicle', function ()
    return lib.callback.await('rhd_garage:cb:getDataVehicle', false)
end)

--- for qb-houses
RegisterNetEvent('qb-garages:client:setHouseGarage', function(house, hasKey)
    if Config.HouseGarages[house] then
        if lasthouse ~= house then
            if lasthouse then
                houseZone[lasthouse]:remove()
            end
            if hasKey and Config.HouseGarages[house].takeVehicle.x then
                local coords = Config.HouseGarages[house].takeVehicle
                local vec4 = vec4(coords.x, coords.y, coords.z, coords.w)
                local vec3 = vec3(coords.x, coords.y, coords.z)
                houseZone[house] = Utils.createGarageZone({
                    coords = vec3,
                    inside = function ()
                        if not Zone.drawtext then
                            Utils.createGarageRadial({
                                gType = 'garage',
                                vType = 'car',
                                garage = house,
                                coords = vec4
                            })

                            Utils.drawtext('show', house:upper(), 'warehouse')
                            Zone.drawtext = not Zone.drawtext
                        end
                    end,
                    exit = function ()
                        Utils.removeRadial('garage')
                    end
                })
                lasthouse = house
            end
        end
    end
end)

RegisterNetEvent('qb-garages:client:houseGarageConfig', function(garageConfig)
    Config.HouseGarages = garageConfig
end)

RegisterNetEvent('qb-garages:client:addHouseGarage', function(house, garageInfo)
    Config.HouseGarages[house] = garageInfo
end)
