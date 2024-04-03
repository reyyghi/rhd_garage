local CreatedZone = {}
local zone = {}

local blips = lib.load('client.blip')

function zone.refresh ()
    if not GarageZone or type(GarageZone) ~= "table" then return end

    blips.refresh(GarageZone)
    if next(CreatedZone) then
        for k, v in pairs(CreatedZone) do
            v:remove()
        end
    end

    for k, v in pairs(GarageZone) do
        CreatedZone[k] = lib.zones.poly({
            points = v.zones.points,
            thickness = v.zones.thickness,
            onEnter = function ()
                if not v.impound then
                    if v.gang then if not utils.GangCheck({garage = k, gang = v.gang}) then return end end
                    if v.job then if not utils.JobCheck({garage = k, job = v.job}) then return end end
                end

                utils.drawtext('show', k:upper(), 'warehouse')

                radFunc.create({
                    id = "open_garage",
                    label = locale("rhd_garage:open_garage"),
                    icon = "warehouse",
                    event = "rhd_garage:radial:open",
                    args = {
                        garage = k,
                        impound = v.impound,
                        shared = v.shared,
                        type = v.type,
                        spawnpoint = v.spawnPoint
                    }
                })

                if not v.impound then
                    radFunc.create({
                        id = "store_veh",
                        label = locale("rhd_garage:store_vehicle"),
                        icon = "parking",
                        event = "rhd_garage:radial:store",
                        args = {
                            garage = k,
                            impound = v.impound,
                            shared = v.shared,
                            type = v.type
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

function zone.save ( data )
    TriggerServerEvent("rhd_garage:server:saveGarageZone", data)
end

return zone