Garage = {}
Garage.showVeh = nil
local pay = false


local spawn = function ( data )
    Utils.createPlyVeh(data.prop.model, data.coords, function (veh)
        NetworkFadeInEntity(veh, true, false)
        lib.setVehicleProperties(veh, data.prop)
        
        if Config.FuelScript == 'ox_fuel' then
            Entity(veh).state.fuel = data.prop.fuelLevel
        else
            exports[Config.FuelScript]:SetFuel(veh, data.prop.fuelLevel)
        end
        
        Framework.updateState({
            vehicle = veh,
            prop = data.prop,
            plate = Utils.getPlate(data.prop.plate),
            state = 0,
            garage = data.garage
        })
        TriggerEvent("vehiclekeys:client:SetOwner", Utils.getPlate(data.prop.plate))
    end)
end

Garage.actionMenu = function ( data )
    local actionData = {
        id = 'garage_action',
        title = string.upper( data.garage ),
        menu = 'garage_menu',
        onBack = function ()
            if DoesEntityExist(Garage.showVeh) then
                DeleteVehicle(Garage.showVeh)
                Garage.showVeh = nil
            end
        end,
        onExit = function ()
            if DoesEntityExist(Garage.showVeh) then
                DeleteVehicle(Garage.showVeh)
                Garage.showVeh = nil
            end
        end,
        options = {
            {
                title = Config.Garages[data.garage] and Config.Garages[data.garage]['impound'] and locale('rhd_garage:pay_impound') or locale('rhd_garage:take_out_veh'),
                icon = Config.Garages[data.garage] and Config.Garages[data.garage]['impound'] and 'hand-holding-dollar' or 'caret-right',
                onSelect = function ()
                    if DoesEntityExist(Garage.showVeh) then
                        DeleteVehicle(Garage.showVeh)
                        Garage.showVeh = nil
                    end

                    if Config.Garages[data.garage] and Config.Garages[data.garage].impound then
                        local impoundPrice = Config.ImpoundPrice[GetVehicleClassFromName(data.prop.model)]
                        Utils.createMenu({
                            id = 'pay_methode',
                            title = string.upper(locale('rhd_garage:pay_methode')),
                            options = {
                                {
                                    title = string.upper(locale('rhd_garage:pay_methode_cash')),
                                    icon = 'dollar-sign',
                                    description = locale('rhd_garage:pay_with_cash'),
                                    onSelect = function ()  
                                        if Framework.getMoney('cash') < impoundPrice then return Utils.notif(locale('rhd_garage:not_enough_cash'), 'error') end
                                        if Framework.removeMoney('cash', impoundPrice) then
                                            Utils.notif(locale('rhd_garage:success_pay_impound'), 'success')
                                            return spawn( data )
                                        end
                                    end
                                },
                                {
                                    title = string.upper(locale('rhd_garage:pay_methode_bank')),
                                    icon = 'fab fa-cc-mastercard',
                                    description = locale('rhd_garage:pay_with_bank'),
                                    onSelect = function ()  
                                        if Framework.getMoney('bank') < impoundPrice then return Utils.notif(locale('rhd_garage:not_enough_bank'), 'error') end
                                        if Framework.removeMoney('bank', impoundPrice) then
                                            Utils.notif(locale('rhd_garage:success_pay_impound'), 'success')
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
            }
        }
    }

    Utils.createMenu(actionData)
end

Garage.openMenu = function ( data )
    if not data then return end
    
    local menuData = {
        id = 'garage_menu',
        title = string.upper( data.garage ),
        options = {}
    }

    local vehData = Framework.getdbVehicle( data.garage )

    if not vehData then 
        menuData.options[#menuData.options+1] = {
            title = string.upper(locale('rhd_garage:no_vehicles_in_garage')),
            disabled = true
        }
        return Utils.createMenu(menuData)
    end

    for i=1, #vehData do
        local vehProp = vehData[i].vehicle
        local gState = vehData[i].state
        local pName = vehData[i].owner
        local engine = vehProp.engineHealth
        local body = vehProp.bodyHealth
        local fuel = vehProp.fuelLevel
        local plate = Utils.getPlate(vehProp.plate)
        local shared_garage = Config.Garages[data.garage] and Config.Garages[data.garage]['shared']
        local impound_garage = Config.Garages[data.garage] and Config.Garages[data.garage]['impound']
        local disabled = false
        local description = ''

        if gState == 0 then
            if DoesEntityExist(GlobalState.veh[plate]) then
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

        menuData.options[#menuData.options+1] = {
            title = string.format('%s [ %s ]', Framework.getVehName( vehData[i].model or vehProp.model ), plate),
            icon = 'car',
            disabled = disabled,
            description = description:upper(),
            metadata = {
                { label = 'Fuel', value = math.ceil(fuel) .. '%', progress = math.ceil(fuel) },
                { label = 'Body', value = math.ceil(body / 10) .. '%', progress = math.ceil(body) },
                { label = 'Engine', value = math.ceil(engine/ 10) .. '%', progress = math.ceil(engine) }
            },
            onSelect = function ()
                local vehInArea = lib.getClosestVehicle(data.coords.xyz)
                if DoesEntityExist(vehInArea) then return Utils.notif(locale('rhd_garage:no_parking_spot'), 'error') end

                Garage.showVeh = Utils.createPlyVeh(vehProp.model, data.coords)
                NetworkFadeInEntity(Garage.showVeh, true, false)
                FreezeEntityPosition(Garage.showVeh, true)
                SetVehicleDoorsLocked(Garage.showVeh, 2)
                lib.setVehicleProperties(Garage.showVeh, vehProp)

                if pay then 
                    pay = not pay
                end

                Garage.actionMenu({
                    prop = vehProp,
                    coords = data.coords,
                    garage = data.garage
                })
            end,
        }
    end

    Utils.createMenu(menuData)
end

Garage.storeVeh = function ( data )
    local prop = lib.getVehicleProperties(data.vehicle)
    local plate = Utils.getPlate(prop.plate)
    local shared = Config.Garages[data.garage] and Config.Garages[data.garage]['shared'] or false
    if not Framework.isPlyVeh(plate, shared) then return Utils.notif(locale('rhd_garage:not_owned'), 'error') end
    if DoesEntityExist(data.vehicle) then
        SetEntityAsMissionEntity(data.vehicle, true, true)
        DeleteVehicle(data.vehicle)
        Framework.updateState({
            vehicle = nil,
            prop = prop,
            plate = plate,
            state = 1,
            garage = data.garage
        })
        Utils.notif(locale('rhd_garage:success_stored'), 'success')
    end
end

--- exports 
exports('openMenu', function ( data )
    return Garage.openMenu( data )
end)

exports('storeVehicle', function ( data )
    return Garage.storeVeh( data )
end)
