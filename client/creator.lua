local Zones = lib.load('client.zone')
local Zones_Creator = lib.load('modules.zone')
local spawnPoint = lib.load('modules.spawnpoint')

--- Blip Input
---@param impound boolean
---@return promise
local function blipInput(impound)
    local p = promise.new()
    CreateThread(function()
        local results = {type = impound and 68 or 357, color = 3}
        local blipinput = lib.inputDialog('BLIP', {
            { type = 'number', label = locale("rhd_garage:input.admin.creator_bliptype"), placeholder = '357'},
            { type = 'number', label = locale("rhd_garage:input.admin.creator_blipcolor"), placeholder = '3'},
        })
    
        local hi = blipinput
        results.type = hi and hi[1] or results.type
        results.color = hi and hi[2] or results.color
        p:resolve(results)
    end)

    return p
end

--- Create garage input
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
                { type = 'checkbox', label = "Specific Spawn Point"},
            })
            if input then
                local Impound = not input[5] and input[4] or false

                local newData = {
                    label = input[1],
                    type = input[2],
                    blip = input[3] and Citizen.Await(blipInput(Impound)) or nil,
                    zones = zones,
                    impound = Impound,
                    shared = input[5],
                    spawnPoint = input[6] and Citizen.Await(spawnPoint.create()) or nil
                }

                GarageZone[newData.label] = {
                    type = newData.type,
                    blip = newData.blip,
                    zones = newData.zones,
                    impound = newData.impound,
                    shared = newData.shared,
                    spawnPoint = newData.spawnPoint
                }
                
                utils.notify(locale("rhd_garage:notify.admin.success_create", newData.label:upper()), "success")
                Zones.save( GarageZone )
            end
        end
    })
end

--- Delete garage by index
---@param garage {index: string}
local function delete(garage)
    GarageZone[garage.index] = nil
    utils.notify(locale("rhd_garage:notify.admin.success_deleted", garage.index), "success")
    Zones.save( GarageZone )
end

--- Set blip garage
---@param garage {index: string}
local function setBlip(garage)
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
                        GarageZone[garage.index].blip = {
                            type = blipinput[1],
                            color = blipinput[2]
                        }
                        utils.notify(locale("rhd_garage:notify.admin.success_editblip"), "success")
                        Zones.save( GarageZone )
                    end
                end
            },
            {
                title = locale("rhd_garage:context.admin.blip_remove"),
                icon = "trash",
                onSelect = function()
                    GarageZone[garage.index].blip = nil
                    utils.notify("Blip berhasil di hapus", "success")
                    Zones.save( GarageZone )
                end
            }
        }
    }
    utils.createMenu(blipContext)
end

--- Change garage locations
---@param garage {index: string}
local function changeLocation(garage)
    Zones_Creator.startCreator({
        type = "poly",
        onCreated = function (zones)
            GarageZone[garage.index].zones = zones
            utils.notify(locale("rhd_garage:notify.admin.success_changelocation"), "success")
            Zones.save( GarageZone )
        end
    })
end

--- Teleport to garage location
---@param garage {index: string, value: table}
local function teleportToLocation(garage)
    local data = garage.value
    local coords = data.zones.points[1]
    DoScreenFadeOut(500)
    Wait(1000)
    SetPedCoordsKeepVehicle(cache.ped, coords.x, coords.y, coords.z)
    DoScreenFadeIn(500)
end

--- Change garage label
---@param garage {index: string, value: table}
local function changeGarageLabel(garage)
    local inputLabel = lib.inputDialog(locale("rhd_garage:input.admin.header_changelabel"), {
        { type = 'input', label = locale("rhd_garage:input.admin.label_changelabel"), placeholder = 'Alta Garage, Pilbox Garage, Etc', required = true, min = 1 },
    })
    
    if inputLabel then
        GarageZone[inputLabel[1]] = garage.value
        GarageZone[garage.index] = nil
        utils.notify(locale("rhd_garage:notify.admin.success_changelabel", inputLabel[1]))
        Zones.save( GarageZone )
    end
end

--- Edit the spawn point
---@param garage {index:string, value:table}
local function setspawnpoint(garage)
    local asp = GarageZone[garage.index].spawnPoint or {}
    local noEmpty = asp and #asp > 0
    local context = {
        id = 'rhd:csp',
        title = 'Spawn Point',
        options = {}
    }

    if noEmpty then
        for i=1, #asp do
            context.options[#context.options+1] = {
                title = "Point #" .. i,
                icon = "location-dot",
                description = "click me to teleport to my location",
                onSelect = function ()
                    local coords = asp[i]
                    DoScreenFadeOut(500)
                    Wait(1000)
                    SetPedCoordsKeepVehicle(cache.ped, coords.x, coords.y, coords.z)
                    DoScreenFadeIn(500)
                end
            }
        end
    end

    context.options[#context.options+1] = {
        title = "Add Point",
        icon = "plus",
        onSelect = function ()
            local pr = Citizen.Await(spawnPoint.create())
            if not pr then return end
            GarageZone[garage.index].spawnPoint = utils.mergeArray(asp, pr)
            utils.notify("The spawn point has been successfully set", "success", 8000)
            Zones.save(GarageZone)
        end
    }

    if noEmpty then
        context.options[#context.options+1] = {
            title = "Remove Point",
            icon = 'minus',
            onSelect = function ()
                local input = lib.inputDialog('REMOVE POINT', {
                    { type = 'number', label = 'point index?', placeholder = '', required = true, min = 1, max = #asp },
                })

                if input then
                    local point = asp[input[1]]
                    if point then
                        table.remove(asp, input[1])
                        GarageZone[garage.index].spawnPoint = asp
                        utils.notify("point with ID " .. input[1] .. " was successfully deleted", "success", 8000)

                        if #GarageZone[garage.index].spawnPoint < 1 then
                            GarageZone[garage.index].spawnPoint = nil
                        end
                        
                        Zones.save(GarageZone)
                    end
                end
            end
        }
    end
    utils.createMenu(context)
end

--- Add & Remove job
---@param garage {index: string, value: table}
local function jobOptions(garage)
    local key = garage.index
    local value = garage.value

    local contextJob = {
        id = "rhd_contextJob",
        title = key:upper(),
        menu = "rhd:action_garage",
        onBack = function() end,
        options = {}
    }

    if value.job and type(value.job) == "table" then
        for name, grade in pairs(value.job) do
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
                                    value.job[name] = nil

                                    if not next(value.job) then
                                        value.job = nil
                                    end

                                    GarageZone[key].job = value.job
                                    utils.notify(locale("rhd_garage:notify.admin.success_deleted_access"), "success")
                                    Zones.save( GarageZone )
                                end
                            }
                        }
                    }
                    utils.createMenu(contextJob2)
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
                if not value.job then value.job = {} end
                value.job[input[1]] = tonumber(input[2])
                GarageZone[key].job = value.job
                utils.notify(locale("rhd_garage:notify.admin.success_added_access", input[1]))
                Zones.save( GarageZone )
            end
        end
    }
    
    utils.createMenu(contextJob)
end

--- Add & Remove gang
---@param garage {index: string, value: table}
local function gangOptions(garage)
    local key = garage.index
    local value = garage.value

    local contextGang = {
        id = "rhd_contextGang",
        title = key:upper(),
        menu = "rhd:action_garage",
        onBack = function() end,
        options = {}
    }

    if value.gang and type(value.gang) == "table" then
        for name, grade in pairs(value.gang) do
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
                                    value.gang[name] = nil

                                    if not next(value.gang) then
                                        value.gang = nil
                                    end
                                    
                                    GarageZone[key].gang = value.gang
                                    utils.notify(locale("rhd_garage:notify.admin.success_deleted_access"), "success")
                                    Zones.save( GarageZone )
                                end
                            }
                        }
                    }
                    utils.createMenu(contextGang2)
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
                if not value.gang then value.gang = {} end
                value.gang[input[1]] = tonumber(input[2])
                GarageZone[key].gang = value.gang
                utils.notify(locale("rhd_garage:notify.admin.success_added_access", input[1]))
                Zones.save( GarageZone )
            end
        end
    }
    
    utils.createMenu(contextGang)
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
            description = locale("rhd_garage:context.admin.listgarage_description", v.impound and "Impound" or v.shared and "Shared" or "Public", utils.garageType("getstring", v.type)),
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
                            onSelect = delete,
                            args = {
                                index = k
                            }
                        },
                        {
                            title = locale("rhd_garage:context.admin.blip_setting"),
                            icon = "map",
                            onSelect = setBlip,
                            args = {
                                index = k
                            }
                        },
                        {
                            title = locale("rhd_garage:context.admin.options_changelocation"),
                            icon = "location-dot",
                            onSelect = changeLocation,
                            args = {
                                index = k
                            }
                        },
                        {
                            title = locale("rhd_garage:context.admin.tptoloc"),
                            icon = "location-dot",
                            onSelect = teleportToLocation,
                            args = {
                                value = v
                            }
                        },
                        {
                            title = locale("rhd_garage:context.admin.options_changelabel"),
                            icon = "pen-to-square",
                            onSelect = changeGarageLabel,
                            args = {
                                index = k,
                                value = v
                            }
                        },
                        {
                            title = "Spawn Point",
                            icon = "location-dot",
                            onSelect = setspawnpoint,
                            args = {
                                index = k
                            }
                        },
                    }
                }

                if not v.impound and not v.gang then
                    context2.options[#context2.options+1] = {
                        title = locale("rhd_garage:context.admin.job_title"),
                        icon = "briefcase",
                        onSelect = jobOptions,
                        args = {
                            index = k,
                            value = v
                        }
                    }
                end

                if not v.impound and not v.job then
                    context2.options[#context2.options+1] = {
                        title = locale("rhd_garage:context.admin.gang_title"),
                        icon = "users",
                        onSelect = gangOptions,
                        args = {
                            index = k,
                            value = v
                        }
                    }
                end
                utils.createMenu(context2)
            end
        }
    end
    utils.createMenu(context)
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