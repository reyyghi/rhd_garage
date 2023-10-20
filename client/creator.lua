local Zones = require "client.zone"
local Zones_Creator = require "modules.zone"

AddEventHandler('QBCore:Client:OnPlayerLoaded', Zones.refresh)
RegisterNetEvent("rhd_garage:client:refreshZone", Zones.refresh)
RegisterNetEvent("rhd_garage:client:createGarage", function ()
    Zones_Creator.startCreator({
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
                        impound = newData.impound,
                        shared = newData.shared
                    }
                    
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
            onSelect = function ()
                
            end
        }   
    end
end)

CreateThread(function ()
    if LocalPlayer.state.isLoggedIn then
        Zones.refresh()
    end
end)