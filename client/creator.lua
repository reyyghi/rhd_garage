local Zones = lib.load('client.zone')
local Zones_Creator = lib.load('modules.zone')
local Utils = lib.load('modules.utils')

local function createGarage ()
    Zones_Creator.startCreator({
        type = "poly",
        onCreated = function (zones)
            local input = lib.inputDialog('RHD GARAGE (Creator)', {
                { type = 'input', label = locale("rhd_garage:input.admin.creator_labelgarage"), placeholder = 'Alta Garage', required = true },
                { type = 'multi-select', label = locale("rhd_garage:input.admin.creator_typevehicle"), options = {
                    {value = "car", label = "Car"},
                    {value = "boat", label = "Boats"},
                    {value = "helicopter", label = "Helicopter"},
                    {value = "planes", label = "Planes"},
                    {value = "motorcycle", label = "Motorcycle"},
                    {value = "cycles", label = "Bicycle"},
                }, required = true},
                { type = 'checkbox', label = "Use Blip"},
                { type = 'checkbox', label = "Impound"},
                { type = 'checkbox', label = "Shared"},
            })
            
            if input then

                local Impound = not input[5] and input[4] or false

                local newData = {
                    label = input[1],
                    type = input[2],
                    blip = nil,
                    zones = zones,
                    impound = Impound,
                    shared = input[5]
                }

                if input[3] then
                    local blipinput = lib.inputDialog('BLIP', {
                        { type = 'number', label = locale("rhd_garage:input.admin.creator_bliptype"), placeholder = '357', required = true},
                        { type = 'number', label = locale("rhd_garage:input.admin.creator_blipcolor"), placeholder = '3', required = true},
                    })

                    newData.blip = {}
                    newData.blip.type = Impound and 68 or 357
                    newData.blip.color = 3

                    if blipinput then
                        newData.blip.type = blipinput[1]
                        newData.blip.color = blipinput[2]
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
end

local function listGarage ()
    local context = {
        id = 'rhd:list_garage',
        title = locale("rhd_garage:context.admin.listgarage_title"),
        options = {}
    }
    for k, v in pairs(GarageZone) do
        context.options[#context.options+1] = {
            title = k:upper(),
            icon = "warehouse",
            description = locale("rhd_garage:context.admin.listgarage_description", v.impound and "Impound" or v.shared and "Shared" or "Public", Utils.garageType("getstring", v.type)),
            onSelect = function ()
                local context2 = {
                    id = "rhd:action_garage",
                    title = k:upper(),
                    menu = "rhd:list_garage",
                    onBack = function()

                    end,
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
                            title = locale("rhd_garage:context.admin.blip_setting"),
                            icon = "map",
                            onSelect = function()
                                local blipContext = {
                                    id = "blip_setting",
                                    title = locale("rhd_garage:context.admin.blip_setting"),
                                    menu = "rhd:action_garage",
                                    onBack = function()

                                    end,
                                    options = {
                                        {
                                            title = locale("rhd_garage:context.admin.blip_edit"),
                                            icon = "pen-to-square",
                                            onSelect = function ()
                                                local blipinput = lib.inputDialog('BLIP', {
                                                    { type = 'number', label = locale("rhd_garage:input.admin.creator_bliptype"), required = true },
                                                    { type = 'number', label = locale("rhd_garage:input.admin.creator_blipcolor"), required = true },
                                                })
                            
                                                if blipinput then
                                                    GarageZone[k].blip = {
                                                        type = blipinput[1],
                                                        color = blipinput[2]
                                                    }
                                                    Utils.notify(locale("rhd_garage:notify.admin.success_editblip"), "success")
                                                    Zones.save( GarageZone )
                                                end
                                            end
                                        },
                                        {
                                            title = locale("rhd_garage:context.admin.blip_remove"),
                                            icon = "trash",
                                            onSelect = function()
                                                GarageZone[k].blip = nil
                                                Utils.notify("Blip berhasil di hapus", "success")
                                                Zones.save( GarageZone )
                                            end
                                        }
                                    }
                                }
                                Utils.createMenu(blipContext)
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
                            title = locale("rhd_garage:context.admin.tptoloc"),
                            icon = "location-dot",
                            onSelect = function ()
                                local coords = v.zones.points[1]
                                DoScreenFadeOut(500)
                                Wait(1000)
                                SetPedCoordsKeepVehicle(cache.ped, coords.x, coords.y, coords.z)
                                DoScreenFadeIn(500)
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
                                menu = "rhd:action_garage",
                                onBack = function()

                                end,
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
                                menu = "rhd:action_garage",
                                onBack = function()

                                end,
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
end

CreateThread(function ()
    while not fw.playerLoaded do print("load garage data") Wait(100) end
    if fw.playerLoaded then
        Zones.refresh()
        print("Garage data has been successfully loaded")
    end
end)

AddStateBagChangeHandler("rhd_garage_zone", "global", function (bagName, key, value)
    if value then
        GarageZone = value
        Zones.refresh()
    end
end)

RegisterNetEvent("rhd_garage:client:createGarage", createGarage)
RegisterNetEvent("rhd_garage:client:listgarage", listGarage)