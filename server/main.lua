lib.callback.register('rhd_garage:cb:removeMoney', function(src, type, amount)
    return Framework.server.removeMoney(src, type, amount)
end)

RegisterNetEvent("rhd_garage:server:updateState", function ( data )
    local prop = data.prop
    local state = data.state
    local garage = data.garage
    local plate = data.plate
    
    if Framework.esx() then
        MySQL.update('UPDATE owned_vehicles SET stored = ?, vehicle = ?, garage = ? WHERE plate = ?', { state, json.encode(prop), garage, plate })
        return
    end

    MySQL.update('UPDATE player_vehicles SET state = ?, mods = ?, garage = ? WHERE plate = ? or fakeplate = ?', { state, json.encode(prop), garage, plate })
end)

RegisterNetEvent("rhd_garage:server:saveGarageZone", function(fileData)
    if type(fileData) ~= "table" or type(fileData) == "nil" then
        return
    end

    local getData = function(fileData)
        local result = {}
    
        for key, data in pairs(fileData) do
            if fileData[key] then
                local points = {}
                for i = 1, #data.zones.points do
                    points[#points + 1] = ('vec3(%s, %s, %s),\n\t\t\t\t'):format(data.zones.points[i].x, data.zones.points[i].y, data.zones.points[i].z)
                end

                local groupsStr = ''
                if data.job and table.type(data.job) ~= "empty" then
                    groupsStr = '{'
                    for group, level in pairs(data.job) do
                        groupsStr = groupsStr .. string.format('["%s"] = %s,', group, level)
                    end
                    groupsStr = groupsStr .. '}'
                else
                    groupsStr = 'nil'
                end

                local gangStr = ''
                if data.gang and table.type(data.gang) ~= "empty" then
                    gangStr = '{'
                    for group, level in pairs(data.gang) do
                        gangStr = gangStr .. string.format('["%s"] = %s,', group, level)
                    end
                    gangStr = gangStr .. '}'
                else
                    gangStr = 'nil'
                end

                local blip = 'nil'
                if data.blip then
                    blip = ('{ type = %s, color = %s }'):format(data.blip.type, data.blip.color)
                end
    
                result[#result + 1] = ('\t["%s"] = {\n\t    type = "%s",\n\t    blip = %s,\n\t    zones = {\n\t        points = {\n\t            %s\n\t        },\n\t        thickness = "%s"\n\t    },\n\t    job = %s,\n\t    gang = %s,\n\t    impound = %s,\n\t    shared = %s,\n\t},\n'):format(
                key, data.type, blip, table.concat(points), data.zones.thickness, groupsStr, gangStr, data.impound, data.shared)
            end
        end
    
        return table.concat(result, "\n")
    end

    TriggerClientEvent("rhd_garage:client:refreshZone", -1, fileData)
    local serializedData = ('return {\n%s\n}'):format(getData(fileData))
    SaveResourceFile(GetCurrentResourceName(), 'data/garage.lua', serializedData, -1)
end)

RegisterNetEvent("rhd_garage:server:saveCustomVehicleName", function (fileData)
    local getData = function(fileData)
        local result = {}
    
        for key, data in pairs(fileData) do
            if fileData[key] then
                result[#result + 1] = ('\t["%s"] = {\n\t    name = "%s",\n\t},\n'):format(
                key, data.name)
            end
        end
    
        return table.concat(result, "\n")
    end

    local serializedData = ('return {\n%s\n}'):format(getData(fileData))
    SaveResourceFile(GetCurrentResourceName(), 'data/customname.lua', serializedData, -1)
end)