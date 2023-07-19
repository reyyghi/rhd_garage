if not Framework.qb() then return end

local qb = exports['qb-core']:GetCoreObject()

local lasthouse = nil
local houseZone = {}

local radialOpenGarage = nil
local radialSaveGarage = nil
local radialPublicImpound = nil

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
lib.callback.register('rhd_garage:cb:cekEntity', function (plate)
    if DoesEntityExist(GlobalState.veh[plate]) then
        return true
    end
    return false
end)

exports('getDataVehicle', function ()
    return lib.callback.await('rhd_garage:cb:getDataVehicle', false)
end)

--- for qb-radialmenu
Framework.addRadial = function ( data )
    if data.gType == 'garage' then
        radialOpenGarage = exports['qb-radialmenu']:AddOption({
            id = 'open_garage',
            title = locale('rhd_garage:open_garage'),
            icon = 'warehouse',
            type = 'client',
            event = 'rhd_garage:client:radialOpenGarage',
            data = data,
            shouldClose = true
        }, radialOpenGarage)

        radialSaveGarage = exports['qb-radialmenu']:AddOption({
            id = 'store_vehicle',
            title = locale('rhd_garage:store_vehicle'),
            icon = 'square-parking',
            type = 'client',
            event = 'rhd_garage:client:radialSaveVehicle',
            data = data,
            shouldClose = true
        }, radialSaveGarage)
    elseif data.gType == 'impound' then
        radialPublicImpound = exports['qb-radialmenu']:AddOption({
            id = 'open_impound',
            title = locale('rhd_garage:access_impound'),
            icon = 'warehouse',
            type = 'client',
            event = 'rhd_garage:client:radialOpenGarage',
            data = data,
            shouldClose = true
        }, radialPublicImpound)
    end
end

Framework.removeRadial = function ( type )
    if type == 'garage' then
        exports['qb-radialmenu']:RemoveOption(radialOpenGarage)
        exports['qb-radialmenu']:RemoveOption(radialSaveGarage)
    elseif type == 'impound' then
        exports['qb-radialmenu']:RemoveOption(radialPublicImpound)
    end
end

RegisterNetEvent('rhd_garage:client:radialOpenGarage', function( self )
    local data = self.data
    if cache.vehicle then return end
    Garage.openMenu( data )
end)

RegisterNetEvent('rhd_garage:client:radialSaveVehicle', function( self )
    local data = self.data
    local plyVeh = cache.vehicle
    if not cache.vehicle then
        plyVeh = lib.getClosestVehicle(GetEntityCoords(cache.ped))
    end

    if not Utils.VehicleCheck( data.vType, plyVeh ) then return Utils.notif(locale('rhd_garage:invalid_vehicle_class', string.lower(data.garage))) end

    if DoesEntityExist(plyVeh) then
        if cache.vehicle then
            if cache.seat ~= -1 then return end
            TaskLeaveAnyVehicle(cache.ped, true, 0)
            Wait(1000)
        end
        Garage.storeVeh({
            vehicle = plyVeh,
            garage = data.garage,
        })
    else
        Utils.notif(locale('rhd_garage:not_vehicle_exist'), 'error')
    end
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
