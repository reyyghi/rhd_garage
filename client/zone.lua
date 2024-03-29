local Utils = require "modules.utils"
local blips = require "client.blip"

local CreatedZone = {}
local zone = {}

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
                    if v.gang then if not Utils.GangCheck({garage = k, gang = v.gang}) then return end end
                    if v.job then if not Utils.JobCheck({garage = k, job = v.job}) then return end end
                end

                Utils.drawtext('show', k:upper(), 'warehouse')

                Utils.createRadial({
                    id = "open_garage",
                    label = locale("rhd_garage:open_garage"),
                    icon = "warehouse",
                    event = "rhd_garage:radial:open",
                    garage = {
                        label = k,
                        impound = v.impound,
                        shared = v.shared,
                        type = v.type
                    }
                })

                if not v.impound then
                    Utils.createRadial({
                        id = "store_veh",
                        label = locale("rhd_garage:store_vehicle"),
                        icon = "parking",
                        event = "rhd_garage:radial:store",
                        garage = {
                            label = k,
                            impound = v.impound,
                            shared = v.shared,
                            type = v.type
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

function zone.save ( data )
    TriggerServerEvent("rhd_garage:server:saveGarageZone", data)
end

return zone