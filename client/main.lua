local Utils = require "modules.utils"
local Deformation = require 'modules.deformation'

Garage = {}

local ColorLevel = {}
local VehicleShow = nil

local spawn = function ( data )

    lib.requestModel(data.model)
    local serverData = lib.callback.await("rhd_garage:cb_server:createVehicle", false, {
        model = data.model,
        plate = data.plate,
        coords = data.coords,
        vehtype = Utils.getVehicleTypeByModel(data.model)
    })

    if serverData.netId < 1 then
        return
    end

    while not NetworkDoesEntityExistWithNetworkId(serverData.netId) do Wait(10) end
    local veh = NetworkGetEntityFromNetworkId(serverData.netId)
    
    while GetVehicleNumberPlateText(veh) ~= serverData.plate do
        SetVehicleNumberPlateText(serverData.plate:trim()) Wait(10)
    end
    
    SetVehicleNumberPlateText(veh, serverData.plate)
    SetVehicleOnGroundProperly(veh)

    if Config.SpawnInVehicle then
        Wait(200)
        TaskWarpPedIntoVehicle(cache.ped, veh, -1)
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
                icon = data.impound and 'hand-holding-dollar' or 'sign-out-alt',
                iconAnimation = Config.IconAnimation,
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
                                    iconAnimation = Config.IconAnimation,
                                    onSelect = function ()  
                                        if Framework.client.getMoney('cash') < impoundPrice then return Utils.notify(locale('rhd_garage:not_enough_cash'), 'error') end
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
                                    iconAnimation = Config.IconAnimation,
                                    onSelect = function ()  
                                        if Framework.client.getMoney('bank') < impoundPrice then return Utils.notify(locale('rhd_garage:not_enough_bank'), 'error') end
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
        if Config.TransferVehicle.enable then
            actionData.options[#actionData.options+1] = {
                title = locale("rhd_garage:transferveh_title"),
                icon = "exchange-alt",
                iconAnimation = Config.IconAnimation,
                metadata = {
                    price = lib.math.groupdigits(Config.TransferVehicle.price, '.')
                },
                onSelect = function ()
                    DeleteVehicle(VehicleShow)
                    VehicleShow = nil

                    local transferInput = lib.inputDialog(data.vehName:upper(), {
                        { type = 'number', label = 'Player Id', required = true },
                    })
                    
                    if transferInput then
                        local clData = {
                            targetSrc = transferInput[1],
                            plate = data.plate,
                            price = Config.TransferVehicle.price,
                            garage = data.garage
                        }
                        lib.callback('rhd_garage:cb_server:transferVehicle', false, function (success, information)
                            if not success then return
                                Utils.notify(information, "error")
                            end

                            Utils.notify(information, "success")
                        end, clData)
                    end
                end
            }
        end

        if Config.SwapGarage.enable then
            actionData.options[#actionData.options+1] = {
                title = locale('rhd_garage:swapgarage_title'),
                icon = "retweet",
                iconAnimation = Config.IconAnimation,
                metadata = {
                    price = lib.math.groupdigits(Config.SwapGarage.price, '.')
                },
                onSelect = function ()
                    DeleteVehicle(VehicleShow)
                    VehicleShow = nil

                    local garageTable = function ()
                        local result = {}
                        for k, v in pairs(GarageZone) do
                            if k ~= data.garage and not v.impound then
                                result[#result+1] = { value = k }
                            end
                        end
                        return result
                    end

                    local garageInput = lib.inputDialog(data.garage:upper(), {
                        { type = 'select', label = locale('rhd_garage:swapgarage_input_label'), options = garageTable(), required = true},
                    })

                    if garageInput then
                        local vehdata = {
                            plate = data.plate,
                            newgarage = garageInput[1]
                        }

                        if Framework.client.getMoney('cash') < Config.SwapGarage.price then return Utils.notify(locale("rhd_garage:swapgarage_need_money", lib.math.groupdigits(Config.SwapGarage.price, '.')), 'error') end
                        local success = lib.callback.await('rhd_garage:cb_server:removeMoney', false, 'cash', Config.SwapGarage.price)
                        if not success then return end

                        lib.callback('rhd_garage:cb_server:swapGarage', false, function (success)
                            if not success then return
                                Utils.notify(locale("rhd_garage:swapgarage_error"), "error")
                            end
    
                            Utils.notify(locale('rhd_garage:swapgarage_success', vehdata.newgarage), "success")
                        end, vehdata)
                    end
                end
            }
        end

        actionData.options[#actionData.options+1] = {
            title = locale('rhd_garage:change_veh_name'),
            -- description = locale('rhd_garage:change_veh_name_price', lib.math.groupdigits(Config.changeNamePrice)),
            icon = 'pencil',
            iconAnimation = Config.IconAnimation,
            metadata = {
                price = lib.math.groupdigits(Config.SwapGarage.price, '.')
            },
            onSelect = function ()
                DeleteVehicle(VehicleShow)
                VehicleShow = nil
                
                local input = lib.inputDialog(data.vehName, {
                    { type = 'input', label = '', placeholder = locale('rhd_garage:change_veh_name_input'), required = true, max = 20 },
                })
                
                if input then
                    if Framework.client.getMoney('cash') < Config.changeNamePrice then return Utils.notify(locale('rhd_garage:change_veh_name_nocash'), 'error') end

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

        local vehicleLabel = ('%s [ %s ]'):format(CNV[plate:trim()] and CNV[plate:trim()].name or Framework.client.getVehName( vehModel ), plate)
        
        if Utils.garageType("check", data.type, Utils.getTypeByClass(vehicleClass)) then
            menuData.options[#menuData.options+1] = {
                title = vehicleLabel,
                icon = icon,
                disabled = disabled,
                description = description:upper(),
                iconAnimation = Config.IconAnimation,
                metadata = {
                    { label = 'Fuel', value = math.floor(fuel) .. '%', progress = math.floor(fuel), colorScheme = ColorLevel[math.floor(fuel)]},
                    { label = 'Body', value = math.floor(body / 10) .. '%', progress = math.floor(body / 10), colorScheme = ColorLevel[math.floor(body / 10)]},
                    { label = 'Engine', value = math.floor(engine/ 10) .. '%', progress = math.floor(engine / 10), colorScheme = ColorLevel[math.floor(engine / 10)]}
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

--- Thread
CreateThread(function ()
    if not next(ColorLevel) then
        for i=1, 100 do
            if i < 25 then
                ColorLevel[i] = "red"
            elseif i >= 25 and i < 50 then
                ColorLevel[i] = "#E86405"
            elseif i >= 50 and i < 75 then
                ColorLevel[i] = "#E8AC05"
            elseif i >= 75 then
                ColorLevel[i] = "green"
            end
        end
    end
end)

--- exports 
exports('openMenu', Garage.openMenu)
exports('storeVehicle', Garage.storeVeh)
