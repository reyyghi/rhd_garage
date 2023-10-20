local Zones = require "modules.zone"
local Utils = require "modules.utils"
local blips = require "client.blip"

local refreshZone = function ( data )
    data = data or GarageZone
    blips.refresh(data)
    for k, v in pairs(data) do
        lib.zones.poly({
            points = v.zones.points,
            thickness = v.zones.thickness,
            onEnter = function ()
                if not v.impound then
                    if v.gang then if not Utils.GangCheck({garage = k, gang = v.gang}) then return end end
                    if v.job then if not Utils.JobCheck({garage = k, job = v.job}) then return end end
                end

                Utils.drawtext('show', k:upper(), 'warehouse')

                print(v.impound)

                Utils.createRadial({
                    id = "open_garage",
                    label = locale("rhd_garage:open_garage"),
                    icon = "warehouse",
                    event = "rhd_garage:radial:open",
                    action = function ()
                        if not cache.vehicle then
                            Garage.openMenu( {garage = k, impound = v.impound, shared = v.shared} )
                        end
                    end
                })

                if not v.impound then
                    Utils.createRadial({
                        id = "store_veh",
                        label = locale("rhd_garage:store_vehicle"),
                        icon = "parking",
                        event = "rhd_garage:radial:store",
                        action = function ()
                            local vehicle = cache.vehicle
                            if not vehicle then
                                vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped))
                            end
                            if not Utils.classCheck( v.type, vehicle ) then return Utils.notify(locale('rhd_garage:invalid_vehicle_class', k:lower())) end
                            if DoesEntityExist(vehicle) then
                                if cache.vehicle then
                                    if cache.seat ~= -1 then return end
                                    TaskLeaveAnyVehicle(cache.ped, true, 0)
                                    Wait(1000)
                                end
    
                                Garage.storeVeh({
                                    vehicle = vehicle,
                                    garage = k,
                                })
                            else
                                Utils.notify(locale('rhd_garage:not_vehicle_exist'), 'error')
                            end
                        end
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

local saveData = function ( data )
    TriggerServerEvent("rhd_garage:server:saveGarageZone", data)
end

CreateThread(function ()
    if LocalPlayer.state.isLoggedIn then
        refreshZone()
        blips.refresh()
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', refreshZone)
RegisterNetEvent("rhd_garage:client:refreshZone", refreshZone)
RegisterNetEvent("rhd_garage:client:createGarage", function ()
    Zones.startCreator({
        type = "poly",
        onCreated = function (zones)
            local input = lib.inputDialog('RHD GARAGE (Creator)', {
                { type = 'input', label = 'Garage Label', placeholder = 'Alta Garage', required = true },
                { type = 'select', label = 'Vehicle Type', options = {
                    {value = "car", label = "Car"},
                    {value = "boat", label = "Boats"},
                    {value = "helicopter", label = "Helicopter"},
                    {value = "planes", label = "Planes"}
                }, required = true},
                { type = 'checkbox', label = "Blip"},
                { type = 'checkbox', label = "Impound"},
                { type = 'checkbox', label = "Shared"},
            })
            
            if input then
                local newData = {
                    label = input[1],
                    type = input[2],
                    blip = { type = 357, color = 3 },
                    zones = zones,
                    job = {},
                    impound = not input[5] and input[4] or false,
                    shared = input[5]
                }

                if input[3] then
                    local blipinput = lib.inputDialog('BLIP', {
                        { type = 'number', label = 'Blip Type', placeholder = '357'},
                        { type = 'number', label = 'Blip Color', placeholder = '3'},
                    })

                    if blipinput then
                        newData.blip.type = blipinput[1] or 357
                        newData.blip.color = blipinput[2] or 3
                    end

                    GarageZone[newData.label] = {
                        type = newData.type,
                        blip = newData.blip,
                        zones = newData.zones,
                        job = newData.job,
                        impound = newData.impound,
                        shared = newData.shared
                    }
                    
                    saveData( GarageZone )
                    return
                end

                GarageZone[newData.label] = {
                    type = newData.type,
                    blip = newData.blip,
                    zones = newData.zones,
                    job = newData.job,
                    impound = newData.impound,
                    shared = newData.shared
                }
                
                saveData( GarageZone )
            end
            
        end
    })
end)

RegisterNetEvent("rhd_garage:client:listgarage", function ()
    local context = {
        id = 'rhd:list_garage',
        title = locale("rhd_garage:context.admin.listgarage_title"),
        options = {}
    }
    for k, v in pairs(GarageZone) do
        context.options[#context.options+1] = {
            title = k:upper(),
            icon = ""
        }   
    end
end)