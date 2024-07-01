local CreatedZone = {}
local zone = {}
local ped = nil
local stui = false
local blips = lib.load('client.blip')

--- Job & Gang Checking
---@param key string
---@param val table
---@return boolean
function zone.authorize(key, val)
    if not val.impound then
        if val.gang then if not utils.GangCheck({garage = key, gang = val.gang}) then return false end end
        if val.job then if not utils.JobCheck({garage = key, job = val.job}) then return false end end
    end

    return true
end

function zone.refresh ()
    if not GarageZone or type(GarageZone) ~= "table" then return end

    blips.refresh(GarageZone)
    if next(CreatedZone) then
        for k, v in pairs(CreatedZone) do
            v:remove()
        end
    end

    for k, v in pairs(GarageZone) do
        local zoneOptions = {
            points = v.zones.points,
            thickness = v.zones.thickness,
        }

        local args = {
            garage = k,
            impound = v.impound,
            shared = v.shared,
            type = v.type,
            spawnpoint = v.spawnPoint
        }

        if type(v.interaction) == "table" then
            
            function zoneOptions:inside()
                if not stui then
                    local dl = cache.vehicle and ('[E] - %s'):format(k) or k
                    utils.drawtext('show', dl:upper(), 'warehouse')
                    stui = true
                end
                if IsControlJustPressed(0, 38) and cache.vehicle then
                    if not zone.authorize(k, v) then return end
                    exports.rhd_garage:storeVehicle(args)
                end
            end

            function zoneOptions:onEnter()
                if not zone.authorize(k, v) then return end
                local model = v.interaction.model
                local pc = v.interaction.coords
                ped = utils.createTargetPed(model, pc, {
                    {
                        name = "open_garage",
                        label = "Open Garage",
                        icon = "fas fa-warehouse",
                        action = function ()
                            args.targetped = true
                            exports.rhd_garage:openMenu(args)
                        end,
                        distance = 1.5
                    }
                })
            end

            function zoneOptions:onExit()
                stui = false
                utils.drawtext('hide')
                local id = Config.Target == "ox" and "open_garage" or "Open Garage"
                utils.removeTargetPed(ped, id)
            end
        elseif v.interaction == "keypressed" then
            function zoneOptions:inside()
                if IsControlJustPressed(0, 38) then

                    if not zone.authorize(k, v) then
                        return
                    end

                    if cache.vehicle then
                        return exports.rhd_garage:storeVehicle(args)
                    end

                    exports.rhd_garage:openMenu(args)
                end
            end

            function zoneOptions:onEnter()
                if not zone.authorize(k, v) then return end
                local dl = ('[E] - %s'):format(k)
                utils.drawtext('show', dl:upper(), 'warehouse')
            end

            function zoneOptions:onExit()
                utils.drawtext('hide')
            end
        elseif v.interaction == "radial" then
            function zoneOptions:onEnter()
                if not zone.authorize(k, v) then return end
                utils.drawtext('show', k:upper(), 'warehouse')

                radFunc.create({
                    id = "open_garage",
                    label = v.impound and locale('garage.access_impound') or locale("garage.open"),
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
                        label = locale("garage.store"),
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
            end

            function zoneOptions:onExit()
                utils.drawtext('hide')

                radFunc.remove("open_garage")
                radFunc.remove("store_veh")
            end
        end
        CreatedZone[k] = lib.zones.poly(zoneOptions)
    end
end

lib.onCache('vehicle', function(value)
    stui = false
end)

function zone.save ( data )
    TriggerServerEvent("rhd_garage:server:saveGarageZone", data)
end

return zone