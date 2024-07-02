if not Config.UsePoliceImpound then return end

local VehicleShow = nil
local Deformation = lib.load('modules.deformation')

PoliceImpound = {}

local function deletePreviewVehicle ()
    if VehicleShow and DoesEntityExist(VehicleShow) then
        SetEntityAsMissionEntity(VehicleShow, true, true)
        DeleteVehicle(VehicleShow)
    end
end

---@param data GarageVehicleData
local function spawnvehicle ( data )
    local vehData = lib.callback.await('rhd_garage:cb_server:getvehiclePropByPlate', false, data.plate)
    if not vehData then return error('Failed to load vehicle data with number plate ' .. data.plate) end
    local vehEntity = utils.createPlyVeh(vehData.model, data.coords)
    SetVehicleOnGroundProperly(vehEntity)
    if Config.SpawnInVehicle then TaskWarpPedIntoVehicle(cache.ped, vehEntity, -1) end
    SetVehicleEngineHealth(vehEntity, vehData.engine + 0.0)
    SetVehicleBodyHealth(vehEntity, vehData.body + 0.0)
    utils.setFuel(vehEntity, vehData.fuel)
    vehFunc.svp(vehEntity, vehData.mods)
    Deformation.set(vehEntity, vehData.deformation)
    TriggerServerEvent("rhd_garage:server:removeFromPoliceImpound", vehData.plate)
    TriggerEvent("vehiclekeys:client:SetOwner", vehData.plate:trim())
end

---@param garage table
local function openpoliceImpound ( garage )
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
    
            local paidstatus = locale("context.policeImpound.not_paid")
    
            if paid > 0 then
                paidstatus = locale("context.policeImpound.paid")
            end
    
            context.options[#context.options+1] = {
                title = ("%s [%s]"):format(vehname, plate:upper()),
                description = locale("context.policeImpound.vehdescription", fine, paidstatus),
                metadata = {
                    OWNER = owner,
                    OFFICER = officer,
                    ['PICKUP DATE'] = date,
                },
                iconAnimation = Config.IconAnimation,
                onSelect = function ()
                    local coords = vec(GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 2.0, 0.5), GetEntityHeading(cache.ped)+90)
                    local vehInArea = lib.getClosestVehicle(coords.xyz)
                    if DoesEntityExist(vehInArea) then return utils.notify(locale('rhd_garage:no_parking_spot'), 'error') end

                    VehicleShow = utils.createPlyVeh(props.model, coords)
                    NetworkFadeInEntity(VehicleShow, true, false)
                    FreezeEntityPosition(VehicleShow, true)
                    SetVehicleDoorsLocked(VehicleShow, 2)
                    if props and next(props) then
                        vehFunc.svp(VehicleShow, props)
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
                                description = locale("context.policeImpound.vehdescription", fine, paidstatus),
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
                            title = locale("context.policeImpound.sendBill"),
                            icon = "dollar-sign",
                            iconAnimation = Config.IconAnimation,
                            onSelect = function ()
                                deletePreviewVehicle()
                                TriggerServerEvent("rhd_garage:server:policeImpound.sendBill", citizenid, fine, plate)
                            end
                        }
                    elseif paid > 0 then
                        context2.options[#context2.options+1] = {
                            title = locale("context.policeImpound.takeOutVeh"),
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
                                    spawnvehicle( data )
                                end
                            end
                        }
                    end

                    utils.createMenu(context2)
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
    utils.createMenu(context)
end

local function checkAvailableGarage ()
    local AvailableGarage = {}

    for k,v in pairs(Config.PoliceImpound.location) do
        AvailableGarage[#AvailableGarage+1] = {
            value = v.label
        }
    end

    return AvailableGarage
end

local function impoundVehicle (vehicle)
    local vehprop = vehFunc.gvp(vehicle)
    local plate = vehprop.plate
    local vehdata = vehFunc.gvibp(plate:trim())
    local garageList = checkAvailableGarage()

    if not vehdata then return
        utils.notify(locale('notify.error.npc_vehicle'), 'error')
    end

    if #garageList < 1 then return
        utils.notify(locale('no_available_policeimpound_location'), 'error', 12000)
    end

    local vehName = vehdata.vehicle_name or fw.gvn(vehdata.vehicle)
    local customvehName = CNV[plate:trim()] and CNV[plate:trim()].name
    local vehlabel = customvehName or vehName

    local owner = vehdata.owner
    local ownerName = owner.name
    local ownerCitizenid = owner.citizenid
    local officerName = fw.gn()

    local input = lib.inputDialog(("%s [%s]"):format(vehlabel, plate:upper()), {
        { type = 'input', label = locale('input.police_impound.veh_owner'), placeholder = ownerName:upper(), disabled = true },
        { type = 'number', label = locale('input.police_impound.fine'), required = true, default = 10000, min = 1, max = 1000000 },
        { type = 'select', label = locale('input.police_impound.confiscate_garage_loc'), options = garageList, default = garageList[1] },
        { type = 'date', label = locale('input.police_impound.confiscate_until'), icon = {'far', 'calendar'}, default = true, format = "DD/MM/YYYY" }
    })
    
    if input then
        local sendToServer = {
            citizenid = ownerCitizenid,
            owner = ownerName,
            officer = officerName,
            fine = input[2],
            garage = input[3],
            prop = vehprop,
            plate = plate:trim(),
            vehicle = vehlabel,
            date =  math.floor(input[4] / 1000),
            deformation = Deformation.get(vehicle)
        }

        if lib.progressBar({
            duration = 5000,
            label = locale('progressbar.confiscate_vehicle'),
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
                utils.notify(locale('notify.success.confiscate_vehicle', ownerName, input[3]), "success")
            end, sendToServer)

            ClearPedTasks(cache.ped)
        else
            ClearPedTasks(cache.ped)
        end
    end
end

local function setUpTarget ( )
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
    local TargetLable = locale('target.confiscate_veh')

    if Config.Target == "ox" then
        exports.ox_target:addGlobalVehicle({
            {
                label = TargetLable,
                icon = 'fas fa-car',
                bones = bones,
                groups = TargetData.groups,
                onSelect = function (data)
                    impoundVehicle(data.entity)
                end,
                distance = 1.5
            }
        })
    elseif Config.Target == "qb" then
        exports['qb-target']:AddTargetBone(bones, {
            options = {
                [TargetLable] = {
                    icon = 'fas fa-car',
                    label = TargetLable,
                    action = function(veh)
                        impoundVehicle(veh)
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
        header = locale('input.police_impound.fine_header', fw.gn()),
        content = locale('input.police_impound.fine_content', lib.math.groupdigits(fine, '.')),
        centered = true,
        cancel = true,
        labels = {
            confirm = locale('input.police_impound.fine_pay'),
            cancel = locale('input.police_impound.fine_ignore')
        }
    })

    if alert == "confirm" then
        utils.createMenu({
            id = 'rhd_garage:policeImpound.payoptions',
            title = locale('context.insurance.pay_methode_header'):upper(),
            onExit = function ()
                continue = true
            end,
            options = {
                {
                    title = locale('context.insurance.pay_methode_cash_title'):upper(),
                    icon = 'dollar-sign',
                    iconAnimation = Config.IconAnimation,
                    description = locale('context.insurance.pay_methode_cash_title_desc'),
                    onSelect = function ()

                        if fw.gm('cash') < fine then
                            continue = true
                            utils.notify(locale('notify.error.not_enough_cash'), 'error')
                            return
                        end

                        local success = lib.callback.await('rhd_garage:cb_server:removeMoney', false, 'cash', fine)

                        if success then
                            paid = true
                            continue = true
                            utils.notify("Anda berhasil membayar denda kendaraan anda", "success")
                        else
                            continue = true
                        end
                    end
                },
                {
                    title = locale('context.insurance.pay_methode_bank_title'):upper(),
                    icon = 'fab fa-cc-mastercard',
                    iconAnimation = Config.IconAnimation,
                    description = locale('context.insurance.pay_methode_bank_title_desc'),
                    onSelect = function ()  
                        if fw.gm('bank') < fine then
                            continue = true
                            utils.notify(locale('notify.error.not_enough_bank'), 'error') 
                            return
                        end

                        local success = lib.callback.await('rhd_garage:cb_server:removeMoney', false, 'bank', fine)

                        if success then
                            paid = true
                            continue = true
                            utils.notify("Anda berhasil membayar denda kendaraan anda", "success")
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
        
        setUpTarget()

        for k, v in pairs(Location) do
            if v.blip and v.blip.enable then
                local coords = v.zones.points[1]
                local piBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
                SetBlipSprite(piBlip, v.blip.sprite or 473)
                SetBlipScale(piBlip, 0.9)
                SetBlipColour(piBlip, v.blip.colour or 40)
                SetBlipDisplay(piBlip, 4)
                SetBlipAsShortRange(piBlip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(v.label:upper())
                EndTextCommandSetBlipName(piBlip)
            end

            lib.zones.poly({
                points  = v.zones.points,
                thickness = v.zones.thickness,
                onEnter = function ()
                    if utils.JobCheck({ job = Target.groups}) then

                        utils.drawtext('show', v.label:upper(), 'warehouse')
                        radFunc.create({
                            id = "open_garage_pi",
                            label = locale("garage.open"),
                            icon = "warehouse",
                            event = "rhd_garage:radial:open_policeimpound",
                            args = {
                                label = v.label,
                            }
                        })
                        
                    end
                end,
                onExit = function ()
                    utils.drawtext('hide')
    
                    radFunc.remove("open_garage")
                    radFunc.remove("store_veh")
                end
            })
        end
    end
end)

exports('openpoliceImpound', openpoliceImpound)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if VehicleShow and DoesEntityExist(VehicleShow) then
            SetEntityAsMissionEntity(VehicleShow, true, true)
            DeleteVehicle(VehicleShow)
        end
    end
end)