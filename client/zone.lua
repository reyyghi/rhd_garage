local Utils = require "modules.utils"
local blips = require "client.blip"

local CreatedZone = {}
local zone = {}

function zone.refresh ( data )
    data = data or GarageZone
    blips.refresh(data)

    for k, v in pairs(data) do
        if CreatedZone[k] then
            CreatedZone[k]:remove()
        end
    end

    for k, v in pairs(data) do
        CreatedZone[k] = lib.zones.poly({
            points = v.zones.points,
            thickness = v.zones.thickness,
            onEnter = function ()
                print(json.encode(v.job))
                if not v.impound then
                    if v.gang then if not Utils.GangCheck({garage = k, gang = v.gang}) then return end end
                    if v.job then if not Utils.JobCheck({garage = k, job = v.job}) then return end end
                end

                Utils.drawtext('show', k:upper(), 'warehouse')

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

function zone.save ( data )
    TriggerServerEvent("rhd_garage:server:saveGarageZone", data)
end

return zone