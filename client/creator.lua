local Zones = require "client.zone"
local Zones_Creator = require "modules.zone"
local Utils = require "modules.utils"

RegisterNetEvent("rhd_garage:client:loadedZone", Zones.refresh)
RegisterNetEvent("rhd_garage:client:refreshZone", Zones.refresh)
RegisterNetEvent("rhd_garage:client:createGarage", function ()
    Zones_Creator.startCreator({
        type = "poly",
        onCreated = function (zones)
            local input = lib.inputDialog('RHD GARAGE (Creator)', {
                { type = 'input', label = locale("rhd_garage:input.admin.creator_labelgarage"), placeholder = 'Alta Garage', required = true },
                { type = 'select', label = locale("rhd_garage:input.admin.creator_typevehicle"), options = {
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

                local Impound = not input[5] and input[4] or false
                local defaultBlip = {}
                if not Impound then
                    defaultBlip.type = Config.defaultBlip.garage[input[2]].type
                    defaultBlip.color = Config.defaultBlip.garage[input[2]].color
                else
                    defaultBlip.type = Config.defaultBlip.insurance[input[2]].type
                    defaultBlip.color = Config.defaultBlip.insurance[input[2]].color
                end

                local newData = {
                    label = input[1],
                    type = input[2],
                    blip = { type = defaultBlip.type, color = defaultBlip.color },
                    zones = zones,
                    impound = Impound,
                    shared = input[5]
                }

                if input[3] then
                    local blipinput = lib.inputDialog('BLIP', {
                        { type = 'number', label = locale("rhd_garage:input.admin.creator_bliptype"), placeholder = '357'},
                        { type = 'number', label = locale("rhd_garage:input.admin.creator_blipcolor"), placeholder = '3'},
                    })

                    if blipinput then
                        newData.blip.type = blipinput[1] or defaultBlip.type
                        newData.blip.color = blipinput[2] or defaultBlip.color
                    end

                    GarageZone[newData.label] = {
                        type = newData.type,
                        blip = newData.blip,
                        zones = newData.zones,
                        impound = newData.impound,
                        shared = newData.shared
                    }
                    
                    Utils.notify(locale("rhd_garage:notify.admin.success_create", newData.label:upper()), "success")
                    Zones.save( GarageZone )
                    return
                end

                GarageZone[newData.label] = {
                    type = newData.type,
                    blip = newData.blip,
                    zones = newData.zones,
                    impound = newData.impound,
                    shared = newData.shared
                }
                
                Utils.notify(locale("rhd_garage:notify.admin.success_create", newData.label:upper()), "success")
                Zones.save( GarageZone )
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
            icon = "warehouse",
            description = locale("rhd_garage:context.admin.listgarage_description", v.impound and "Impound" or v.shared and "Shared" or "Public", v.type),
            onSelect = function ()
                local context2 = {
                    id = "rhd:action_garage",
                    title = k:upper(),
                    options = {
                        {
                            title = locale("rhd_garage:context.admin.options_delete"),
                            icon = "trash",
                            onSelect = function ()
                                GarageZone[k] = nil
                                Utils.notify(locale("rhd_garage:notify.admin.success_deleted", k), "success")
                                Zones.save( GarageZone )
                            end
                        },
                        {
                            title = locale("rhd_garage:context.admin.options_changelocation"),
                            icon = "location-dot",
                            onSelect = function ()
                                Zones_Creator.startCreator({
                                    type = "poly",
                                    onCreated = function (zones)
                                        GarageZone[k].zones = zones
                                        Utils.notify(locale("rhd_garage:notify.admin.success_changelocation"), "success")
                                        Zones.save( GarageZone )
                                    end
                                })
                            end
                        },
                        {
                            title = locale("rhd_garage:context.admin.options_changelabel"),
                            icon = "pen-to-square",
                            onSelect = function ()
                                local inputLabel = lib.inputDialog(locale("rhd_garage:input.admin.header_changelabel"), {
                                    { type = 'input', label = locale("rhd_garage:input.admin.label_changelabel"), placeholder = 'Alta Garage, Pilbox Garage, Etc', required = true },
                                })
                                
                                if inputLabel and #inputLabel[1] > 0 then
                                    GarageZone[inputLabel[1]] = v
                                    GarageZone[k] = nil
                                    Utils.notify(locale("rhd_garage:notify.admin.success_changelabel", inputLabel[1]))
                                    Zones.save( GarageZone )
                                end
                            end
                        },
                    }
                }

                if not v.impound and not v.gang then
                    context2.options[#context2.options+1] = {
                        title = locale("rhd_garage:context.admin.job_title"),
                        icon = "briefcase",
                        onSelect = function ()
                            local contextJob = {
                                id = "rhd_contextJob",
                                title = k:upper(),
                                options = {}
                            }

                            if v.job and type(v.job) == "table" then
                                for name, grade in pairs(v.job) do
                                    contextJob.options[#contextJob.options+1] = {
                                        title = locale("rhd_garage:context.admin.job_description", name, grade),
                                        icon = "briefcase",
                                        onSelect = function ()
                                            local contextJob2 = {
                                                id = "rhd_contextJob2",
                                                title = name:upper(),
                                                options = {
                                                    {
                                                        title = locale("rhd_garage:context.admin.delete"),
                                                        icon = "trash",
                                                        onSelect = function ()
                                                            v.job[name] = nil

                                                            if not next(v.job) then
                                                                v.job = nil
                                                            end

                                                            Utils.notify(locale("rhd_garage:notify.admin.success_deleted_access"), "success")
                                                            Zones.save( GarageZone )
                                                        end
                                                    }
                                                }
                                            }
                                            Utils.createMenu(contextJob2)
                                        end
                                    }
                                end
                            end

                            contextJob.options[#contextJob.options+1] = {
                                title = locale("rhd_garage:context.admin.add_job"),
                                icon = "plus",
                                onSelect = function ()
                                    local input = lib.inputDialog(locale("rhd_garage:input.admin.garage_access"), {
                                        { type = 'input', label = locale("rhd_garage:input.admin.garage_access_job"), placeholder = 'police, ambulance, etc', required = true },
                                        { type = 'number', label = locale("rhd_garage:input.admin.garage_access_grade_job"), required = true}
                                    })
                                    
                                    if input then
                                        if not v.job then v.job = {} end
                                        v.job[input[1]] = tonumber(input[2])
                                        Utils.notify(locale("rhd_garage:notify.admin.success_added_access", input[1]))
                                        Zones.save( GarageZone )
                                    end
                                end
                            }
                            
                            Utils.createMenu(contextJob)
                        end
                    }    
                end

                if not v.impound and not v.job then
                    context2.options[#context2.options+1] = {
                        title = locale("rhd_garage:context.admin.gang_title"),
                        icon = "users",
                        onSelect = function ()
                            local contextGang = {
                                id = "rhd_contextGang",
                                title = k:upper(),
                                options = {}
                            }

                            if v.gang and type(v.gang) == "table" then
                                for name, grade in pairs(v.gang) do
                                    contextGang.options[#contextGang.options+1] = {
                                        title = locale("rhd_garage:context.admin.gang_description", name, grade),
                                        icon = "users",
                                        onSelect = function ()
                                            local contextGang2 = {
                                                id = "rhd_contextGang2",
                                                title = name:upper(),
                                                options = {
                                                    {
                                                        title = locale("rhd_garage:context.admin.delete"),
                                                        icon = "trash",
                                                        onSelect = function ()
                                                            v.gang[name] = nil

                                                            if not next(v.gang) then
                                                                v.gang = nil
                                                            end
                                                            
                                                            Utils.notify(locale("rhd_garage:notify.admin.success_deleted_access"), "success")
                                                            Zones.save( GarageZone )
                                                        end
                                                    }
                                                }
                                            }
                                            Utils.createMenu(contextGang2)
                                        end
                                    }
                                end
                            end

                            contextGang.options[#contextGang.options+1] = {
                                title = locale("rhd_garage:context.admin.add_gang"),
                                icon = "plus",
                                onSelect = function ()
                                    local input = lib.inputDialog(locale("rhd_garage:input.admin.garage_access"), {
                                        { type = 'input', label = locale("rhd_garage:input.admin.garage_access_gang"), placeholder = 'ballas, vagos, etc', required = true },
                                        { type = 'number', label = locale("rhd_garage:input.admin.garage_access_grade_gang"), required = true}
                                    })
                                    
                                    if input then
                                        if not v.gang then v.gang = {} end
                                        v.gang[input[1]] = tonumber(input[2])
                                        Utils.notify(locale("rhd_garage:notify.admin.success_added_access", input[1]))
                                        Zones.save( GarageZone )
                                    end
                                end
                            }
                            
                            Utils.createMenu(contextGang)
                        end
                    }    
                end

                Utils.createMenu(context2)
            end
        }   
    end

    Utils.createMenu(context)
end)

CreateThread(function ()
    if LocalPlayer.state.isLoggedIn then
        Zones.refresh()
    end
end)