PoliceImpound = {}

PoliceImpound.actionGarage = function ( data )
    local actionData = {
        id = 'impound_action',
        title = string.upper( data.garage ),
        menu = 'impoundMenu',
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
                title = locale('rhd_garage:take_out_veh'),
                icon = 'caret-right',
                onSelect = function ()
                    if DoesEntityExist(Garage.showVeh) then
                        DeleteVehicle(Garage.showVeh)
                        Garage.showVeh = nil
                    end

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
                        TriggerServerEvent('rhd_garage:server:removeData', Utils.getPlate(data.prop.plate))
                    end)
                end
            }
        }
    }

    Utils.createMenu(actionData)
end

PoliceImpound.openGarage = function ( data )
    local vehData = lib.callback.await('rhd_garage:cb:getDataPoliceImpound', false)
    if not vehData then return Utils.notif(locale('rhd_garage:policeimpound_notif_not_vehicle')) end
    local impoundMenu = {
        id = 'impoundMenu',
        title = string.upper(data.garage),
        options = {}
    }
    for i=1, #vehData do
        local prop = vehData[i].vehprop
        local disabled = lib.callback.await('rhd_garage:cb:cekDate', false, vehData[i].date)
        impoundMenu.options[#impoundMenu.options+1] = {
            title = ('%s [%s]'):format(vehData[i].vehName, vehData[i].plate),
            icon = 'car',
            metadata = {
                { label = 'Fuel', value = math.ceil(prop.fuelLevel) .. '%', progress = math.ceil(prop.fuelLevel) },
                { label = 'Body', value = math.ceil(prop.bodyHealth / 10) .. '%', progress = math.ceil(prop.bodyHealth / 10) },
                { label = 'Engine', value = math.ceil(prop.engineHealth / 10) .. '%', progress = math.ceil(prop.engineHealth / 10) }
            },
            disabled = not disabled,
            description = locale('rhd_garage:policeimpound_menu_description_owner', vehData[i].owner) .. ' \n' .. locale('rhd_garage:policeimpound_menu_description_date', vehData[i].date) .. ' \n' .. locale('rhd_garage:policeimpound_menu_description_reason', vehData[i].reason),
            onSelect = function ()
                local vehInArea = lib.getClosestVehicle(data.coords.xyz)
                if DoesEntityExist(vehInArea) then return Utils.notif(locale('rhd_garage:no_parking_spot'), 'error') end

                Garage.showVeh = Utils.createPlyVeh(prop.model, data.coords)
                NetworkFadeInEntity(Garage.showVeh, true, false)
                FreezeEntityPosition(Garage.showVeh, true)
                SetVehicleDoorsLocked(Garage.showVeh, 2)
                lib.setVehicleProperties(Garage.showVeh, prop)

                PoliceImpound.actionGarage({
                    prop = prop,
                    coords = data.coords,
                    garage = data.garage
                })
            end
        }
    end
    Utils.createMenu(impoundMenu)
end

PoliceImpound.access = function ( pangkat )
    local job = Framework.playerJob()

    if type(job.grade) == 'table' then
        job.grade = job.grade.level
    end

    if job.name == 'police' and job.grade >= pangkat then
        return true
    end
    return false
end

PoliceImpound.availableGarageCheck = function ( vType )
    for k,v in pairs(Config.policeImpound) do
        if v.type == vType then
            return true
        end
    end
    return false
end

PoliceImpound.ImpoundVeh = function ( Vehicle )
    local vehClass = GetVehicleClass(Vehicle)
    if not PoliceImpound.availableGarageCheck( Utils.getVehType(vehClass)) then return Utils.notif(locale('rhd_garage:policeimpound_no_available_garage'), 'error') end
    local prop = lib.getVehicleProperties(Vehicle)
    local ownerName, vehname = Framework.getVehOwnerName(Utils.getPlate(prop.plate))
    
    local input = lib.inputDialog(string.upper(locale('rhd_garage:policeimpound_input_header', vehname:upper(), Utils.getPlate(prop.plate))), {
        {type = 'input', label = string.upper(locale('rhd_garage:policeimpound_input_label1')), placeholder = ownerName, disabled = true},
        {type = 'input', label = string.upper(locale('rhd_garage:policeimpound_input_label2')), required = true},
        {type = 'date', label = string.upper(locale('rhd_garage:policeimpound_input_label3')), icon = {'far', 'calendar'}, default = true, format = "DD/MM/YYYY"}
      })
    
    if input then
        local data = {}
        data.plate = Utils.getPlate(prop.plate)
        data.vehName = vehname
        data.owner = ownerName
        data.reason = input[2]
        data.date = math.floor(input[3] / 1000)
        data.vehprop = json.encode(prop)

        if lib.progressBar({
            duration = 10000,
            label = locale('rhd_garage:policeimpound_progressbar_label'),
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true
            },
        }) then
            SetEntityAsMissionEntity(Vehicle, true, true)
            DeleteVehicle(Vehicle)
            Framework.updateState({
                vehicle = nil,
                prop = prop,
                plate = data.plate,
                state = 2,
                garage = 'Police Impound'
            })
            TriggerServerEvent('rhd_garage:policeimpound:saveData', data)
            Utils.notif(locale('rhd_garage:policeimpound_notif_success'), 'success')
        else
            print('cancel')
        end
    end
end


CreateThread(function ()
    local bones = {
        'door_dside_f',
        'seat_dside_f',
        'door_pside_f',
        'seat_pside_f',
        'door_dside_r',
        'seat_dside_r',
        'door_pside_r',
        'seat_pside_r',
        'bonnet',
        'boot'
    }
    if Config.Target == 'qb-target' then
        exports['qb-target']:AddTargetBone(bones, {
            options = {
                ["Police Impound"] = {
                    icon = "fas fa-wrench",
                    label = locale('rhd_garage:policeimpound_target'),
                    action = function(veh)
                        PoliceImpound.ImpoundVeh(veh)
                    end,
                    job = 'police',
                    distance = 1.3
                }
            }
        })
    elseif Config.Target == 'ox_target' then
        exports.ox_target:addGlobalVehicle({
            {
                label = locale('rhd_garage:policeimpound_target'),
                icon = 'fas fa-car',
                bones = bones,
                groups = 'police',
                onSelect = function (data)
                    PoliceImpound.ImpoundVeh(data.entity)
                end,
                distance = 1
            }
        })
    end
end)
