local Utils = require "modules.utils"

Garage = {}

local VehicleShow = nil

local spawn = function ( data )
    Utils.createPlyVeh(data.prop.model, data.coords, function (veh)
        NetworkFadeInEntity(veh, true, false)
        lib.setVehicleProperties(veh, data.prop)
        SetVehicleNumberPlateText(veh, data.plate)
        
        if Config.FuelScript == 'ox_fuel' then
            Entity(veh).state.fuel = data.prop.fuelLevel
        else
            exports[Config.FuelScript]:SetFuel(veh, data.prop.fuelLevel)
        end
        
        TriggerServerEvent("rhd_garage:server:updateState", {
            vehicle = veh,
            prop = data.prop,
            plate = data.plate,
            state = 0,
            garage = data.garage
        })
        
        TriggerEvent("vehiclekeys:client:SetOwner", data.prop.plate:trim())
    end)
end

Garage.actionMenu = function ( data )
    local actionData = {
        id = 'garage_action',
        title = data.vehName:upper(),
        menu = 'garage_menu',
        onBack = function ()
            if DoesEntityExist(VehicleShow) then
                DeleteVehicle(VehicleShow)
                VehicleShow = nil
            end
        end,
        onExit = function ()
            if DoesEntityExist(VehicleShow) then
                DeleteVehicle(VehicleShow)
                VehicleShow = nil
            end
        end,
        options = {
            {
                title = data.impound and locale('rhd_garage:pay_impound') or locale('rhd_garage:take_out_veh'),
                icon = data.impound and 'hand-holding-dollar' or 'caret-right',
                onSelect = function ()
                    if DoesEntityExist(VehicleShow) then
                        DeleteVehicle(VehicleShow)
                        VehicleShow = nil
                    end

                    if data.impound then
                        local impoundPrice = Config.ImpoundPrice[GetVehicleClassFromName(data.prop.model)]
                        Utils.createMenu({
                            id = 'pay_methode',
                            title = locale('rhd_garage:pay_methode'):upper(),
                            options = {
                                {
                                    title = locale('rhd_garage:pay_methode_cash'):upper(),
                                    icon = 'dollar-sign',
                                    description = locale('rhd_garage:pay_with_cash'),
                                    onSelect = function ()  
                                        if Framework.getMoney('cash') < impoundPrice then return Utils.notify(locale('rhd_garage:not_enough_cash'), 'error') end
                                        local success = lib.callback.await('rhd_garage:cb:removeMoney', false, 'cash', impoundPrice)
                                        if success then
                                            Utils.notify(locale('rhd_garage:success_pay_impound'), 'success')
                                            return spawn( data )
                                        end
                                    end
                                },
                                {
                                    title = locale('rhd_garage:pay_methode_bank'):upper(),
                                    icon = 'fab fa-cc-mastercard',
                                    description = locale('rhd_garage:pay_with_bank'),
                                    onSelect = function ()  
                                        if Framework.getMoney('bank') < impoundPrice then return Utils.notify(locale('rhd_garage:not_enough_bank'), 'error') end
                                        local success = lib.callback.await('rhd_garage:cb:removeMoney', false, 'bank', impoundPrice)
                                        if success then
                                            Utils.notify(locale('rhd_garage:success_pay_impound'), 'success')
                                            return spawn( data )
                                        end
                                    end
                                }
                            }
                        })
                        return
                    end

                    spawn( data )
                end
            },
            
        }
    }
    
    if not data.impound then
        actionData.options[#actionData.options+1] = {
            title = locale('rhd_garage:change_veh_name'),
            description = locale('rhd_garage:change_veh_name_price', lib.math.groupdigits(Config.changeNamePrice)),
            icon = 'pencil',
            onSelect = function ()
                DeleteVehicle(VehicleShow)
                VehicleShow = nil
                
                local input = lib.inputDialog(data.vehName, {
                    { type = 'input', label = '', placeholder = locale('rhd_garage:change_veh_name_input'), required = true, max = 20 },
                })
                
                if input then
                    if Framework.getMoney('cash') < Config.changeNamePrice then return Utils.notify(locale('rhd_garage:change_veh_name_nocash'), 'error') end

                    local success = lib.callback.await('rhd_garage:cb:removeMoney', false, 'cash', Config.changeNamePrice)
                    if success then
                        CNV[data.plate] = {
                            name = input[1]
                        }
    
                        TriggerServerEvent('rhd_garage:server:saveCustomVehicleName', CNV)
                    end
                end
            end
        }
    end

    Utils.createMenu(actionData)
end


Garage.openMenu = function ( data )
    if not data then return end
    
    local menuData = {
        id = 'garage_menu',
        title = data.garage:upper(  ),
        options = {}
    }

    local vehData = lib.callback.await('rhd_garage:cb:getVehicleList', false, data.garage, data.impound, data.shared)

    if not vehData then 
        menuData.options[#menuData.options+1] = {
            title = locale('rhd_garage:no_vehicles_in_garage'):upper(),
            disabled = true
        }
        return Utils.createMenu(menuData)
    end

    for i=1, #vehData do
        local vehProp = vehData[i].vehicle
        local gState = vehData[i].state
        local pName = vehData[i].owner
        local plate = vehData[i].plate
        local fakeplate = vehData[i].fakeplate
        local engine = vehProp.engineHealth
        local body = vehProp.bodyHealth
        local fuel = vehProp.fuelLevel
        
        local shared_garage = GarageZone[data.garage] and GarageZone[data.garage]['shared']
        local impound_garage = GarageZone[data.garage] and GarageZone[data.garage]['impound']
        local disabled = false
        local description = ''

        if fakeplate ~= nil then
            plate = fakeplate:trim()
        else
            plate = plate:trim()
        end

        if gState == 0 then
            if DoesEntityExist(Utils.getoutsidevehicleByPlate(plate)) then
                disabled = true
                description = 'STATUS: ' ..  locale('rhd_garage:veh_out_garage')
                if shared_garage then
                    description = locale('rhd_garage:shared_owner_label', pName) .. ' \n' .. 'STATUS: ' .. locale('rhd_garage:veh_out_garage')
                end
            else
                if impound_garage then
                    local impoundPrice = Config.ImpoundPrice[GetVehicleClassFromName(vehProp.model)]
                    description = 'STATUS: ' ..  locale('rhd_garage:impound_price', impoundPrice)
                    if shared_garage then
                        description = locale('rhd_garage:shared_owner_label', pName) .. ' \n' .. 'STATUS: ' .. locale('rhd_garage:impound_price', impoundPrice)
                    end
                else
                    disabled = true
                    description = 'STATUS: ' ..  locale('rhd_garage:veh_in_impound')
                    if shared_garage then
                        description = locale('rhd_garage:shared_owner_label', pName) .. ' \n' .. 'STATUS: ' .. locale('rhd_garage:veh_in_impound')
                    end
                end
            end
        elseif gState == 1 then
            description = 'STATUS: ' ..  locale('rhd_garage:veh_in_garage')
            if shared_garage then
                description = locale('rhd_garage:shared_owner_label', pName) .. ' \n' .. 'STATUS: ' .. locale('rhd_garage:veh_in_garage')
            end
        elseif gState == 2 then
            description = 'STATUS: ' .. locale('rhd_garage:phone_veh_in_policeimpound')
            if shared_garage then
                description = locale('rhd_garage:shared_owner_label', pName) .. ' \n' .. 'STATUS: ' .. locale('rhd_garage:phone_veh_in_policeimpound')
            end
        end

        local vehicleLabel = ('%s [ %s ]'):format(CNV[plate:trim()] and CNV[plate:trim()].name or Framework.getVehName( vehData[i].model or vehProp.model ), plate)
        
        menuData.options[#menuData.options+1] = {
            title = vehicleLabel,
            icon = 'car',
            disabled = disabled,
            description = description:upper(),
            metadata = {
                { label = 'Fuel', value = math.ceil(fuel) .. '%', progress = math.ceil(fuel) },
                { label = 'Body', value = math.ceil(body / 10) .. '%', progress = math.ceil(body) },
                { label = 'Engine', value = math.ceil(engine/ 10) .. '%', progress = math.ceil(engine) }
            },
            onSelect = function ()
                local coords = vec(GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 2.0, 0.5), GetEntityHeading(cache.ped)+90)
                local vehInArea = lib.getClosestVehicle(coords.xyz)
                if DoesEntityExist(vehInArea) then return Utils.notify(locale('rhd_garage:no_parking_spot'), 'error') end

                VehicleShow = Utils.createPlyVeh(vehProp.model, coords)
                NetworkFadeInEntity(VehicleShow, true, false)
                FreezeEntityPosition(VehicleShow, true)
                SetVehicleDoorsLocked(VehicleShow, 2)
                lib.setVehicleProperties(VehicleShow, vehProp)

                Garage.actionMenu({
                    prop = vehProp,
                    plate = plate,
                    coords = coords,
                    garage = data.garage,
                    vehName = vehicleLabel,
                    impound = data.impound,
                    shared = data.shared
                })
            end,
        }
    end

    Utils.createMenu(menuData)
end

Garage.storeVeh = function ( data )
    local prop = lib.getVehicleProperties(data.vehicle)
    local plate = prop.plate:trim()
    local shared = data.shared
    local isOwned = lib.callback.await('rhd_garage:cb:getVehOwner', false, plate, shared)
    if not isOwned then return Utils.notify(locale('rhd_garage:not_owned'), 'error') end
    if DoesEntityExist(data.vehicle) then
        SetEntityAsMissionEntity(data.vehicle, true, true)
        DeleteVehicle(data.vehicle)

        TriggerServerEvent('rhd_garage:server:updateState', {
            vehicle = nil,
            prop = prop,
            plate = plate,
            state = 1,
            garage = data.garage
        })
        
        Utils.notify(locale('rhd_garage:success_stored'), 'success')
    end
end

--- exports 
exports('openMenu', function ( data )
    return Garage.openMenu( data )
end)

exports('storeVehicle', function ( data )
    return Garage.storeVeh( data )
end)
