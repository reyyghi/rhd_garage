if not Config.UsePoliceImpound then return end

local VehicleShow = nil

local Utils = require "modules.utils"
local Deformation = require "modules.deformation"

PoliceImpound = {}

local function deletePreviewVehicle ()
    if VehicleShow and DoesEntityExist(VehicleShow) then
        SetEntityAsMissionEntity(VehicleShow, true, true)
        DeleteVehicle(VehicleShow)
    end
end

local spawn = function ( data )

    lib.requestModel(data.props.model)
    local serverData = lib.callback.await("rhd_garage:cb_server:createVehicle", false, {
        model = data.props.model,
        plate = data.plate,
        coords = data.coords,
        vehtype = Utils.getVehicleTypeByModel(data.props.model)
    })

    if serverData.netId < 1 then
        return
    end
    
    while not NetworkDoesEntityExistWithNetworkId(serverData.netId) do Wait(10) end
    local veh = NetworkGetEntityFromNetworkId(serverData.netId)

    while Utils.getPlate(veh) ~= serverData.plate do
        SetVehicleNumberPlateText(veh, serverData.plate) Wait(10)
    end

    local PedDriver = GetPedInVehicleSeat(veh, -1)
    if PedDriver > 0 and PedDriver ~= cache.ped then
        DeleteEntity(PedDriver)
    end

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
       
    Deformation.set(veh, data.deformation)
    TriggerServerEvent("rhd_garage:server:removeFromPoliceImpound", serverData.plate)
    TriggerEvent("vehiclekeys:client:SetOwner", serverData.plate:trim())
end

PoliceImpound.open = function ( garage )
    local garage = garage.label

    local vehicle = lib.callback.await("rhd_garage:cb_server:policeImpound.getVehicle", false, garage)

    local context = {
        id = "rhd_garage:policeImpound",
        title = garage:upper(),
        onBack = deletePreviewVehicle,
        onExit = deletePreviewVehicle,
        options = {}
    }

    if vehicle and #vehicle > 0 then
        for k,v in pairs(vehicle) do
            local citizenid = v.citizenid
            local props = v.props
            local deformation = v.deformation
            local plate = v.plate
            local vehname = v.vehicle
            local owner = v.owner
            local officer = v.officer
            local fine = v.fine
            local paid = v.paid
            local date = v.date
    
            local paidstatus = locale("rhd_garage:context.policeImpound.not_paid")
    
            if paid > 0 then
                paidstatus = locale("rhd_garage:context.policeImpound.paid")
            end
    
            context.options[#context.options+1] = {
                title = ("%s [%s]"):format(vehname, plate:upper()),
                description = locale("rhd_garage:context.policeImpound.vehdescription", fine, paidstatus),
                metadata = {
                    OWNER = owner,
                    OFFICER = officer,
                    ['PICKUP DATE'] = date,
                },
                iconAnimation = Config.IconAnimation,
                onSelect = function ()
                    local coords = vec(GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 2.0, 0.5), GetEntityHeading(cache.ped)+90)
                    local vehInArea = lib.getClosestVehicle(coords.xyz)
                    if DoesEntityExist(vehInArea) then return Utils.notify(locale('rhd_garage:no_parking_spot'), 'error') end

                    VehicleShow = Utils.createPlyVeh(props.model, coords)
                    NetworkFadeInEntity(VehicleShow, true, false)
                    FreezeEntityPosition(VehicleShow, true)
                    SetVehicleDoorsLocked(VehicleShow, 2)
                    if props and next(props) then
                        lib.setVehicleProperties(VehicleShow, props)
                    end

                    local context2 = {
                        id = "rhd_garage:policeImpound.action",
                        title = garage:upper(),
                        menu = "rhd_garage:policeImpound",
                        onBack = deletePreviewVehicle,
                        onExit = deletePreviewVehicle,
                        options = {
                            {
                                title = ("%s [%s]"):format(vehname, plate:upper()),
                                description = locale("rhd_garage:context.policeImpound.vehdescription", fine, paidstatus),
                                metadata = {
                                    OWNER = owner,
                                    OFFICER = officer,
                                    ['PICKUP DATE'] = date,
                                },
                                readOnly = true
                            }
                        }
                    }

                    if paid < 1 then
                        context2.options[#context2.options+1] = {
                            title = locale("rhd_garage:context.policeImpound.sendBill"),
                            icon = "dollar-sign",
                            iconAnimation = Config.IconAnimation,
                            onSelect = function ()
                                deletePreviewVehicle()
                                TriggerServerEvent("rhd_garage:server:policeImpound.sendBill", citizenid, fine, plate)
                            end
                        }
                    elseif paid > 0 then
                        context2.options[#context2.options+1] = {
                            title = locale("rhd_garage:context.policeImpound.takeOutVeh"),
                            icon = "car",
                            iconAnimation = Config.IconAnimation,
                            onSelect = function ()
                                deletePreviewVehicle()
                                local checkkDate, day = lib.callback.await("rhd_garage:cb_server:policeImpound.cekDate", false, date)

                                local continue, takeout = false, false
                                
                                if not checkkDate then
                                    local alert = lib.alertDialog({
                                        header = ("Halo %s"):format(fw.gn()),
                                        content = ("waktu penyitaan kendaraan ini masih %s hari lagi, apakah anda ingin tetap mengeluarkan kendaraa ini?"):format(day),
                                        centered = true,
                                        cancel = true,
                                        labels = {
                                            confirm = "Ya",
                                            cancel = "Tidak"
                                        }
                                    })

                                    if alert == "confirm" then
                                        continue = true takeout = true
                                    else
                                        continue = true
                                    end
                                else
                                    continue = true takeout = true
                                end

                                while not continue do
                                    Wait(1000)
                                end

                                if takeout then
                                    local data = {
                                        props = props,
                                        coords = vec(GetEntityCoords(cache.ped), GetEntityHeading(cache.ped)),
                                        plate = plate,
                                        deformation = deformation
                                        
                                    }
                                    spawn( data )
                                end
                            end
                        }
                    end

                    Utils.createMenu(context2)
                end
            }
        end
    end

    if #context.options < 1 then
        context.options[#context.options+1] = {
            title = "Tidak ada Kendaraan",
            disabled = true
        }
    end
    Utils.createMenu(context)
end

PoliceImpound.checkAvailableGarage = function ()
    local AvailableGarage = {}

    for k,v in pairs(Config.PoliceImpound.location) do
        AvailableGarage[#AvailableGarage+1] = {
            value = v.label
        }
    end

    return AvailableGarage
end

PoliceImpound.ImpoundVeh = function ( vehicle )
    local vehprop = lib.getVehicleProperties(vehicle)
    local vehdata = exports.rhd_garage:getvehdataByPlate( vehprop.plate:trim() )
    local garageList = PoliceImpound.checkAvailableGarage()

    if not vehdata then return end
    if #garageList < 1 then return end

    local vehname = CNV[vehprop.plate:trim()]?.name or fw.gvn(vehdata.vehicle)
    local officerName = fw.gn()

    local input = lib.inputDialog(("%s [%s]"):format(vehname, vehprop.plate:upper()), {
        { type = 'input', label = 'PEMILIK', placeholder = vehdata.owner:upper(), disabled = true },
        { type = 'number', label = 'DENDA', required = true, default = 10000, min = 1, max = 1000000 },
        { type = 'select', label = 'GARASI PENYITAAN', options = garageList, default = garageList[1] },
        { type = 'date', label = 'DI SITA SAMPAI?', icon = {'far', 'calendar'}, default = true, format = "DD/MM/YYYY" }
    })
    
    if input then
        local sendToServer = {
            citizenid = vehdata.citizenid,
            owner = vehdata.owner,
            officer = officerName,
            fine = input[2],
            garage = input[3],
            prop = vehprop,
            plate = vehprop.plate:trim(),
            vehicle = vehname,
            date =  math.floor(input[4] / 1000),
            deformation = Deformation.get(vehicle)
        }

        if lib.progressBar({
            duration = 5000,
            label = "Menyita Kendaraan",
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true,
                mouse = false,
            },
            anim = {
                dict = 'missheistdockssetup1clipboard@base',
                clip = 'base',
                flags = 1
            },
            prop = {
                {
                model = `prop_notepad_01`,
                bone = 18905,
                pos = { x = 0.1, y = 0.02, z = 0.05 },
                rot = { x = 10.0, y = 0.0, z = 0.0 },
                },
                {
                    model = 'prop_pencil_01',
                    bone = 58866,
                    pos = { x = 0.11, y = -0.02, z = 0.001 },
                    rot = { x = -120.0, y = 0.0, z = 0.0 },
                },
            },
        })
        then
            lib.callback('rhd_garage:cb_server:policeImpound.impoundveh', false, function ( success )
                SetEntityAsMissionEntity(vehicle, true, true)
                DeleteVehicle(vehicle)
                Utils.notify("Kendaraan berhasil di sita!", "success")
            end, sendToServer)

            ClearPedTasks(cache.ped)
        else
            ClearPedTasks(cache.ped)
        end
    end
end

PoliceImpound.setUpTarget = function ( )
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

    local TargetData = Config.PoliceImpound.Target

    if TargetData.type == "ox" then
        exports.ox_target:addGlobalVehicle({
            {
                label = "Sita Kendaraan",
                icon = 'fas fa-car',
                bones = bones,
                groups = TargetData.groups,
                onSelect = function (data)
                    PoliceImpound.ImpoundVeh(data.entity)
                end,
                distance = 1.5
            }
        })
    elseif TargetData.type == "qb" then
        exports['qb-target']:AddTargetBone(bones, {
            options = {
                ["Sita Kendaraan"] = {
                    icon = 'fas fa-car',
                    label = "Sita Kendaraan",
                    action = function(veh)
                        PoliceImpound.ImpoundVeh(veh)
                    end,
                    job = TargetData.groups,
                    distance = 1.5
                }
            }
        })
    end
end

--- Client Callback
lib.callback.register("rhd_garage:cb_client:sendFine", function ( fine )
    local paid, continue = false, false

    local alert = lib.alertDialog({
        header = ("Halo %s"):format(fw.gn()),
        content = ("anda di minta untuk membayar tagihan kendaraan anda yang di sita oleh polisi sebesar $%s"):format(fine),
        centered = true,
        cancel = true,
        labels = {
            confirm = "Bayar",
            cancel = "Abaikan"
        }
    })

    if alert == "confirm" then
        Utils.createMenu({
            id = 'rhd_garage:policeImpound.payoptions',
            title = 'PILIH METODE PEMBAYARAN',
            onExit = function ()
                continue = true
            end,
            options = {
                {
                    title = locale('rhd_garage:pay_methode_cash'):upper(),
                    icon = 'dollar-sign',
                    iconAnimation = Config.IconAnimation,
                    description = locale('rhd_garage:pay_with_cash'),
                    onSelect = function ()

                        if fw.gm('cash') < fine then
                            continue = true
                            Utils.notify(locale('rhd_garage:not_enough_cash_policeImpound'), 'error')
                            return
                        end

                        local success = lib.callback.await('rhd_garage:cb_server:removeMoney', false, 'cash', fine)

                        if success then
                            paid = true
                            continue = true
                            Utils.notify("Anda berhasil membayar denda kendaraan anda", "success")
                        else
                            continue = true
                        end
                    end
                },
                {
                    title = locale('rhd_garage:pay_methode_bank'):upper(),
                    icon = 'fab fa-cc-mastercard',
                    iconAnimation = Config.IconAnimation,
                    description = locale('rhd_garage:pay_with_bank'),
                    onSelect = function ()  
                        if fw.gm('bank') < fine then
                            continue = true
                            Utils.notify(locale('rhd_garage:not_enough_bank_policeImpound'), 'error') 
                            return
                        end

                        local success = lib.callback.await('rhd_garage:cb_server:removeMoney', false, 'bank', fine)

                        if success then
                            paid = true
                            continue = true
                            Utils.notify("Anda berhasil membayar denda kendaraan anda", "success")
                        else
                            continue = true
                        end
                    end
                }
            },
        })
    else
        continue = true
    end

    while not continue do
        Wait(1000)
    end

    return paid
end)

CreateThread(function()
    local Location = Config.PoliceImpound.location
    local Target = Config.PoliceImpound.Target
    if Config.UsePoliceImpound and next(Location) then
        
        PoliceImpound.setUpTarget()

        for k,v in pairs(Location) do
            lib.zones.poly({
                points  = v.zones.points,
                thickness = v.zones.thickness,
                onEnter = function ()
                    if Utils.JobCheck({ job = Target.groups}) then

                        Utils.drawtext('show', v.label:upper(), 'warehouse')
                        Utils.createRadial({
                            id = "open_garage",
                            label = locale("rhd_garage:open_garage"),
                            icon = "warehouse",
                            event = "rhd_garage:radial:open_policeimpound",
                            garage = {
                                label = v.label,
                            }
                        })
                        
                    end
                end,
                onExit = function ()
                    Utils.drawtext('hide')
    
                    Utils.removeRadial("open_garage")
                    Utils.removeRadial("store_veh")
                end
            })
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if VehicleShow and DoesEntityExist(VehicleShow) then
            SetEntityAsMissionEntity(VehicleShow, true, true)
            DeleteVehicle(VehicleShow)
        end
    end
end)