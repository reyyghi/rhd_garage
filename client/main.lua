local Utils = require "modules.utils"
local Deformation = require 'modules.deformation'

Garage = {}

local VehicleShow = nil

local spawn = function ( data )

    local serverData = lib.callback.await("rhd_garage:cb_server:createVehicle", false, {
        model = data.model,
        plate = data.plate,
        coords = data.coords,
        vehtype = Utils.getVehicleTypeByModel(data.model)
    })

    if serverData.netId < 1 then
        return
    end

    while not NetworkDoesNetworkIdExist(serverData.netId) do Wait(10) end
    local veh = NetworkGetEntityFromNetworkId(serverData.netId)
    NetworkFadeInEntity(veh, true)
    SetVehicleNumberPlateText(veh, serverData.plate)
    SetVehicleOnGroundProperly(veh)

    if serverData.props and next(serverData.props) then
        lib.setVehicleProperties(veh, serverData.props)
    end

    if Config.FuelScript == 'ox_fuel' then
        Entity(veh).state.fuel = serverData.props?.fuelLevel or 100
    else
        exports[Config.FuelScript]:SetFuel(veh, serverData.props?.fuelLevel or 100)
    end
    
    Deformation.set(veh, serverData.deformation)

    TriggerServerEvent("rhd_garage:server:updateState", {
        vehicle = veh,
        prop = serverData.props,
        plate = serverData.plate,
        state = 0,
        garage = data.garage,
        deformation = serverData.deformation
    })
    
    TriggerEvent("vehiclekeys:client:SetOwner", serverData.plate:trim())
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
                                        local success = lib.callback.await('rhd_garage:cb_server:removeMoney', false, 'cash', impoundPrice)
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
                                        local success = lib.callback.await('rhd_garage:cb_server:removeMoney', false, 'bank', impoundPrice)
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

                    local success = lib.callback.await('rhd_garage:cb_server:removeMoney', false, 'cash', Config.changeNamePrice)
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

    data.type = data.type or "car"
    
    local menuData = {
        id = 'garage_menu',
        title = data.garage:upper(),
        options = {}
    }

    local vehData = lib.callback.await('rhd_garage:cb_server:getVehicleList', false, data.garage, data.impound, data.shared)

    for i=1, #vehData do
        local vehProp = vehData[i].vehicle
        local vehModel = vehData[i].model
        local vehDeformation = vehData[i].deformation
        local gState = vehData[i].state
        local pName = vehData[i].owner
        local plate = vehData[i].plate
        local fakeplate = vehData[i].fakeplate
        local engine = vehProp?.engineHealth or 100
        local body = vehProp?.bodyHealth or 100
        local fuel = vehProp?.fuelLevel or 100
        
        local shared_garage = data.shared
        local impound_garage = data.impound
        local disabled = false
        local description = ''

        if fakeplate ~= nil then
            plate = fakeplate:trim()
        else
            plate = plate:trim()
        end

        local vehicleClass = GetVehicleClassFromName(vehModel)
        local vehicleType = Utils.classCheck(vehicleClass)
        local icon = Config.Icons[vehicleType]

        if gState == 0 then
            if DoesEntityExist(Utils.getoutsidevehicleByPlate(plate)) then
                disabled = true
                description = 'STATUS: ' ..  locale('rhd_garage:veh_out_garage')
                if shared_garage then
                    description = locale('rhd_garage:shared_owner_label', pName) .. ' \n' .. 'STATUS: ' .. locale('rhd_garage:veh_out_garage')
                end
            else
                if impound_garage then
                    local impoundPrice = Config.ImpoundPrice[vehicleClass]
                    description = locale('rhd_garage:impound_price', impoundPrice)
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
            disabled = true
            description = 'STATUS: ' .. locale('rhd_garage:phone_veh_in_policeimpound')
            if shared_garage then
                description = locale('rhd_garage:shared_owner_label', pName) .. ' \n' .. 'STATUS: ' .. locale('rhd_garage:phone_veh_in_policeimpound')
            end
        end

        local vehicleLabel = ('%s [ %s ]'):format(CNV[plate:trim()] and CNV[plate:trim()].name or Framework.getVehName( vehModel ), plate)
        
        if Utils.gerageType("check", data.type, Utils.getTypeByClass(vehicleClass)) then
            menuData.options[#menuData.options+1] = {
                title = vehicleLabel,
                icon = icon,
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
    
                    VehicleShow = Utils.createPlyVeh(vehModel, coords)
                    NetworkFadeInEntity(VehicleShow, true, false)
                    FreezeEntityPosition(VehicleShow, true)
                    SetVehicleDoorsLocked(VehicleShow, 2)

                    if vehProp and next(vehProp) then
                        lib.setVehicleProperties(VehicleShow, vehProp)
                    end
    
                    Garage.actionMenu({
                        prop = vehProp,
                        model = vehModel,
                        plate = plate,
                        coords = coords,
                        garage = data.garage,
                        vehName = vehicleLabel,
                        impound = data.impound,
                        shared = data.shared,
                        deformation = vehDeformation
                    })
                end,
            }
        end
    end

    if #menuData.options < 1 then 
        menuData.options[#menuData.options+1] = {
            title = locale('rhd_garage:no_vehicles_in_garage'):upper(),
            disabled = true
        }
    end

    Utils.createMenu(menuData)
end

Garage.storeVeh = function ( data )
    local prop = lib.getVehicleProperties(data.vehicle)
    local plate = prop.plate:trim()
    local shared = data.shared
    local deformation = Deformation.get(data.vehicle)
    local isOwned = lib.callback.await('rhd_garage:cb_server:getvehowner', false, plate, shared)
    if not isOwned then return Utils.notify(locale('rhd_garage:not_owned'), 'error') end
    if DoesEntityExist(data.vehicle) then
        SetEntityAsMissionEntity(data.vehicle, true, true)
        DeleteVehicle(data.vehicle)

        TriggerServerEvent('rhd_garage:server:updateState', {
            vehicle = nil,
            prop = prop,
            plate = plate,
            deformation = deformation,
            state = 1,
            garage = data.garage
        })
        
        Utils.notify(locale('rhd_garage:success_stored'), 'success')
    end
end

--- exports 
exports('openMenu', Garage.openMenu)
exports('storeVehicle', Garage.storeVeh)
