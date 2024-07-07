local zones = require 'modules.zone'
local spawnPoint = require 'modules.spawnpoint'
local pedcreator = require 'modules.pedcreator'

--- Blip Input
---@param impound boolean
---@return promise
local function blipInput(impound, gLabel)
    local p = promise.new()
    CreateThread(function()
        ---@class BlipData
        local br = {}
        
        ::tryAgain::
        local blipinput = lib.inputDialog('BLIP', {
            { type = 'number', label = locale("input.admin.creator_bliptype"), required = true, default = impound and 68 or 357},
            { type = 'number', label = locale("input.admin.creator_blipcolor"), required = true, default = 3},
            { type = 'input', label = locale("input.admin.creator_bliplabel"), required = true, default = gLabel },
        })
    
        local hi = blipinput
        if not hi then
            return
        end

        if hi[3]:isEmpty() then
            goto tryAgain
        end

        br.type = hi[1]
        br.color = hi[2]
        br.label = hi[3]
        p:resolve(br)
    end)
    return Citizen.Await(p)
end

--- Create garage input
local function createGarage ()
    zones.startCreator({
        type = "poly",
        onCreated = function (zones) ---@param zones OxZone
            local input = lib.inputDialog('RHD GARAGE (Creator)', {
                { type = 'input', label = locale("input.admin.creator_labelgarage"), placeholder = 'Alta Garage', required = true },
                { type = 'multi-select', label = locale("input.admin.creator_typevehicle"), options = {
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
                { type = 'select', label = "Interaction", options = {
                    {value = "radial", label = "Radial Menu"},
                    {value = "keypressed", label = "Key Pressed"},
                    {value = "targetped", label = "Target Ped"}
                }, required = true},
            })
            if input then
                local tPed = input[7] == 'targetped'
                local Impound = not input[5] and input[4] or false
                local label = input[1]
                local gtype = input[2]
                local blip = input[3] and blipInput(Impound, label) or nil
                local shared = input[5]
                local sp = input[6] and spawnPoint.create(zones, false) or nil
                local interact = tPed and pedcreator.start(zones) or input[7]

                if tPed and not sp then
                    Wait(1000)
                    sp = spawnPoint.create(zones, true) or nil
                end

                GarageZone[label] = {
                    type = gtype,
                    blip = blip,
                    zones = zones,
                    impound = Impound,
                    shared = shared,
                    spawnPoint = sp,
                    interaction = interact
                }
                
                utils.notify(locale("notify.admin.success_create", label:upper()), "success")
                gzf.save( GarageZone )
            end
        end
    })
end

--- Delete garage by index
---@param garage {index: string}
local function delete(garage)
    GarageZone[garage.index] = nil
    utils.notify(locale("notify.admin.success_deleted", garage.index), "success")
    gzf.save( GarageZone )
end

--- Set blip garage
---@param garage {index: string}
local function setBlip(garage)
    local blipContext = {
        id = "blip_setting",
        title = locale("context.admin.blip_setting"),
        menu = "rhd:action_garage",
        onBack = function()

        end,
        options = {
            {
                title = locale("context.admin.blip_edit"),
                icon = "pen-to-square",
                onSelect = function ()
                    local gBlip = GarageZone[garage.index].blip

                    local placeholder = {
                        type = gBlip and gBlip.type or '',
                        color = gBlip and gBlip.color or '',
                        label = gBlip and gBlip.label or garage.index
                    }

                    local blipinput = lib.inputDialog('BLIP', {
                        { type = 'number', label = locale("input.admin.creator_bliptype"), required = true, default = placeholder.type },
                        { type = 'number', label = locale("input.admin.creator_blipcolor"), required = true, default = placeholder.color },
                        { type = 'input', label = locale("input.admin.creator_bliplabel"), required = true, default = placeholder.label },
                    })

                    if blipinput then
                        GarageZone[garage.index].blip = {
                            type = blipinput[1],
                            color = blipinput[2],
                            label = blipinput[3]
                        }
                        utils.notify(locale("notify.admin.success_editblip"), "success")
                        gzf.save( GarageZone )
                    end
                end
            },
            {
                title = locale("context.admin.blip_remove"),
                icon = "trash",
                onSelect = function()
                    GarageZone[garage.index].blip = nil
                    utils.notify("Blip berhasil di hapus", "success")
                    gzf.save( GarageZone )
                end
            }
        }
    }
    utils.createMenu(blipContext)
end

--- Change garage locations
---@param garage {index: string}
local function changeLocation(garage)
    zones.startCreator({
        type = "poly",
        onCreated = function (zones) ---@param zones OxZone
            GarageZone[garage.index].zones = zones
            utils.notify(locale("notify.admin.success_changelocation"), "success")
            gzf.save( GarageZone )
        end
    })
end

--- Teleport to garage location
---@param garage {index: string, value: GarageData}
local function teleportToLocation(garage)
    local data = garage.value
    local coords = data.zones.points[1]
    DoScreenFadeOut(500)
    Wait(1000)
    SetPedCoordsKeepVehicle(cache.ped, coords.x, coords.y, coords.z)
    DoScreenFadeIn(500)
end

--- Change garage label
---@param garage {index: string, value: GarageData}
local function changeGarageLabel(garage)
    local inputLabel = lib.inputDialog(locale("input.admin.header_changelabel"), {
        { type = 'input', label = locale("input.admin.label_changelabel"), placeholder = 'Alta Garage, Pilbox Garage, Etc', required = true, min = 1 },
    })
    
    if inputLabel then
        GarageZone[inputLabel[1]] = garage.value
        GarageZone[garage.index] = nil
        utils.notify(locale("notify.admin.success_changelabel", inputLabel[1]))
        gzf.save( GarageZone )
    end
end

--- Edit the spawn point
---@param garage {index:string, value:GarageData}
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
            local pr = spawnPoint.create(garage.value.zones, true, asp)
            if not pr then return end
            GarageZone[garage.index].spawnPoint = utils.mergeArray(asp, pr)
            utils.notify("The spawn point has been successfully set", "success", 8000)
            gzf.save(GarageZone)
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
                        
                        gzf.save(GarageZone)
                    end
                end
            end
        }
    end
    utils.createMenu(context)
end

--- Add & Remove job
---@param garage {index: string, value: GarageData}
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
                title = locale("context.admin.job_description", name, grade),
                icon = "briefcase",
                onSelect = function ()
                    local contextJob2 = {
                        id = "rhd_contextJob2",
                        title = name:upper(),
                        options = {
                            {
                                title = locale("context.admin.delete"),
                                icon = "trash",
                                onSelect = function ()
                                    value.job[name] = nil

                                    if not next(value.job) then
                                        value.job = nil
                                    end

                                    GarageZone[key].job = value.job
                                    utils.notify(locale("notify.admin.success_deleted_access"), "success")
                                    gzf.save( GarageZone )
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
        title = locale("context.admin.add_job"),
        icon = "plus",
        onSelect = function ()
            local input = lib.inputDialog(locale("input.admin.garage_access"), {
                { type = 'input', label = locale("input.admin.garage_access_job"), placeholder = 'police, ambulance, etc', required = true },
                { type = 'number', label = locale("input.admin.garage_access_grade_job"), required = true}
            })
            
            if input then
                if not value.job then value.job = {} end
                value.job[input[1]] = tonumber(input[2])
                GarageZone[key].job = value.job
                utils.notify(locale("notify.admin.success_added_access", input[1]))
                gzf.save( GarageZone )
            end
        end
    }
    
    utils.createMenu(contextJob)
end

--- Add & Remove gang
---@param garage {index: string, value: GarageData}
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
                title = locale("context.admin.gang_description", name, grade),
                icon = "users",
                onSelect = function ()
                    local contextGang2 = {
                        id = "rhd_contextGang2",
                        title = name:upper(),
                        options = {
                            {
                                title = locale("context.admin.delete"),
                                icon = "trash",
                                onSelect = function ()
                                    value.gang[name] = nil

                                    if not next(value.gang) then
                                        value.gang = nil
                                    end
                                    
                                    GarageZone[key].gang = value.gang
                                    utils.notify(locale("notify.admin.success_deleted_access"), "success")
                                    gzf.save( GarageZone )
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
        title = locale("context.admin.add_gang"),
        icon = "plus",
        onSelect = function ()
            local input = lib.inputDialog(locale("input.admin.garage_access"), {
                { type = 'input', label = locale("input.admin.garage_access_gang"), placeholder = 'ballas, vagos, etc', required = true },
                { type = 'number', label = locale("input.admin.garage_access_grade_gang"), required = true}
            })
            
            if input then
                if not value.gang then value.gang = {} end
                value.gang[input[1]] = tonumber(input[2])
                GarageZone[key].gang = value.gang
                utils.notify(locale("notify.admin.success_added_access", input[1]))
                gzf.save( GarageZone )
            end
        end
    }
    
    utils.createMenu(contextGang)
end

local function listGarage ()
    local context = {
        id = 'rhd:list_garage',
        title = locale("context.admin.listgarage_title"),
        options = {
            {
                title = locale('context.admin.addnewgarage'),
                icon = 'plus',
                onSelect = createGarage
            }
        }
    }

    for k, v in pairs(GarageZone) do
        context.options[#context.options+1] = {
            title = k:upper(),
            icon = "warehouse",
            description = locale("context.admin.listgarage_description", v.impound and "Impound" or v.shared and "Shared" or "Public", utils.garageType(v.type)),
            onSelect = function ()
                local context2 = {
                    id = "rhd:action_garage",
                    title = k:upper(),
                    menu = "rhd:list_garage",
                    onBack = function()

                    end,
                    options = {
                        {
                            title = locale("context.admin.options_delete"),
                            icon = "trash",
                            onSelect = delete,
                            args = {
                                index = k
                            }
                        },
                        {
                            title = locale("context.admin.blip_setting"),
                            icon = "map",
                            onSelect = setBlip,
                            args = {
                                index = k
                            }
                        },
                        {
                            title = locale("context.admin.options_changelocation"),
                            icon = "location-dot",
                            onSelect = changeLocation,
                            args = {
                                index = k
                            }
                        },
                        {
                            title = locale("context.admin.tptoloc"),
                            icon = "location-dot",
                            onSelect = teleportToLocation,
                            args = {
                                value = v
                            }
                        },
                        {
                            title = locale("context.admin.options_changelabel"),
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
                                index = k,
                                value = v
                            }
                        },
                    }
                }

                if not v.impound and not v.gang then
                    context2.options[#context2.options+1] = {
                        title = locale("context.admin.job_title"),
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
                        title = locale("context.admin.gang_title"),
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
    while not fw.playerLoaded do
        lib.print.warn("Wait for the garage data to finish loading")
        if Config.InDevelopment then
            lib.print.info('Use the /loaded and /reloadcache commands to load garage and player data')
        end
        Wait(1000)
    end
    
    if fw.playerLoaded then
        gzf.refresh()
        lib.print.info("Garage data has been successfully loaded")
    end
end)

RegisterNetEvent('rhd_garage:client:syncConfig', function(newconfig)
    GarageZone = newconfig
    gzf.refresh()
end)

RegisterNetEvent("rhd_garage:client:garagelist", listGarage)