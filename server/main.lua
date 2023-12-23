local Utils = require 'modules.utils'

--- callback
lib.callback.register('rhd_garage:cb_server:removeMoney', function(src, type, amount)
    return Framework.server.removeMoney(src, type, amount)
end)

lib.callback.register('rhd_garage:cb_server:createVehicle', function (_, vehicleData, inside )
    local veh = CreateVehicleServerSetter(vehicleData.model, vehicleData.vehtype, vehicleData.coords.x, vehicleData.coords.y, vehicleData.coords.z, vehicleData.coords.w)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    SetVehicleNumberPlateText(veh, vehicleData.plate)
    return netId
end)

lib.callback.register('rhd_garage:cb_server:getvehowner', function (src, plate, shared)
    local vehicledata = {}
    local isQB = Framework.qb()
    local isOwner = true
    if isQB then
        vehicledata.cid = Framework.server.GetPlayer(src).PlayerData.citizenid
        vehicledata.dbtable = "SELECT 1 FROM `player_vehicles` WHERE `citizenid` = ? and plate = ? OR fakeplate = ?"
        vehicledata.dbvalue = {vehicledata.cid, plate:trim(), plate:trim()}

        if shared then
            vehicledata.dbtable = "SELECT 1 FROM `player_vehicles` WHERE plate = ? OR fakeplate = ?"
            vehicledata.dbvalue = { plate:trim(), plate:trim() }
        end
    else
        vehicledata.cid = Framework.server.GetPlayer(src).identifier
        vehicledata.dbtable = "SELECT `vehicle` FROM `owned_vehicles` WHERE `owner` = ? and plate = ?"
        vehicledata.dbvalue = { vehicledata.cid, plate:trim() }

        if shared then
            vehicledata.dbtable = "SELECT vehicle FROM owned_vehicles WHERE plate = ?"
            vehicledata.dbvalue = { plate:trim() }
        end
    end

    local result = MySQL.single.await(vehicledata.dbtable, vehicledata.dbvalue)

    if not result then
        isOwner = not isOwner
    end
    
     return isOwner
end)


lib.callback.register('rhd_garage:cb_server:getVehicleList', function(src, garage, impound, shared)
    local impound_garage = impound
    local shared_garage = shared

    local garageData = {}
    local isQB = Framework.qb()

    garageData.vehicle = {}

    if isQB then
        garageData.cid = Framework.server.GetPlayer(src).PlayerData.citizenid
        garageData.dbtable = "SELECT vehicle, mods, state, plate, fakeplate, deformation FROM player_vehicles WHERE garage = ? and citizenid = ?"
        garageData.dbvalue = {garage, garageData.cid}

        if impound_garage then
            if shared_garage then return false end
            garageData.dbtable = "SELECT vehicle, mods, state, plate, fakeplate, deformation FROM player_vehicles WHERE state = ? and citizenid = ?"
            garageData.dbvalue = {0, garageData.cid}
        end

        if shared_garage then
            garageData.dbtable = "SELECT player_vehicles.vehicle, player_vehicles.mods, player_vehicles.deformation, player_vehicles.state, player_vehicles.plate, player_vehicles.fakeplate, players.charinfo FROM player_vehicles LEFT JOIN players ON players.citizenid = player_vehicles.citizenid WHERE player_vehicles.garage = ?"
            garageData.dbvalue = {garage}
        end
    else
        garageData.cid = Framework.server.GetPlayer(src).identifier
        garageData.dbtable = "SELECT vehicle, plate, stored, deformation FROM owned_vehicles WHERE garage = ? and owner = ?"
        garageData.dbvalue = {garage, garageData.cid}

        if impound_garage then
            if shared_garage then return false end
            garageData.dbtable = "SELECT vehicle, plate, stored, deformation FROM owned_vehicles WHERE stored = ? and owner = ?"
            garageData.dbvalue = {0, garageData.cid}
        end

        if shared_garage then
            garageData.dbtable = "SELECT owned_vehicles.vehicle, owned_vehicles.plate, owned_vehicles.stored, owned_vehicles.deformation, users.firstname, users.lastname FROM owned_vehicles LEFT JOIN users ON users.identifier = owned_vehicles.owner WHERE owned_vehicles.garage = ?"
            garageData.dbvalue = {garage}
        end
    end

    local result = MySQL.query.await(garageData.dbtable, garageData.dbvalue)

    if result and next(result) then
        if isQB then
            for k, v in pairs(result) do
                local charinfo = json.decode(v.charinfo)
                local vehicles = json.decode(v.mods)
                local deformation = json.decode(v.deformation)
                local state = v.state
                local model = v.vehicle
                local plate = v.plate
                local fakeplate = v.fakeplate
                local ownername = charinfo and ("%s %s"):format(charinfo.firstname, charinfo.lastname)
                
                garageData.vehicle[#garageData.vehicle+1] = {
                    vehicle = vehicles,
                    state = state,
                    model = model,
                    plate = plate,
                    fakeplate = fakeplate,
                    owner = ownername,
                    deformation = deformation
                }
            end
        else
            for k,v in pairs(result) do
                local vehicles = json.decode(v.vehicle)
                local deformation = json.decode(v.deformation)
                local state = v.stored
                local model = vehicles.model
                local plate = v.plate
                local ownername = ("%s %s"):format(v.firstname, v.lastname)

                garageData.vehicle[#garageData.vehicle+1] = {
                    vehicle = vehicles,
                    state = state,
                    model = model,
                    plate = plate,
                    owner = ownername,
                    deformation = deformation
                }
            end
        end
    end
    return garageData.vehicle
end)

lib.callback.register('rhd_garage:cb_server:getvehicledatabyplate', function (src, plate)
    local db = {}
    local ownerName = "Unkown"

    if Framework.qb() then
        db.s = "SELECT player_vehicles.citizenid, player_vehicles.vehicle, player_vehicles.mods, player_vehicles.deformation, player_vehicles.balance, player_vehicles.citizenid, players.charinfo FROM player_vehicles LEFT JOIN players ON players.citizenid = player_vehicles.citizenid WHERE plate = ? OR fakeplate = ?"
        db.v = { plate, plate }
    elseif Framework.esx() then
        db.s = "SELECT owned_vehicles.owner, owned_vehicles.vehicle, owned_vehicles.plate, owned_vehicles.owner, owned_vehicles.deformation, users.firstname, users.lastname FROM owned_vehicles LEFT JOIN users ON users.identifier = owned_vehicles.owner WHERE plate = ?"
        db.v = { plate }
    end

    local data = MySQL.single.await(db.s, db.v)
    if not data then return {} end

    db.data = {}

    if Framework.qb() then
        local mods = json.decode(data.mods)
        local charinfo = json.decode(data.charinfo)
        local deformation = json.decode(data.deformation)
        ownerName = ("%s %s"):format(charinfo.firstname, charinfo.lastname)
        db.data = {
            citizenid = data.citizenid,
            owner = ownerName,
            vehicle = data.vehicle,
            props = mods,
            balance = data.balance,
            deformation = deformation
        }
    elseif Framework.esx() then
        ownerName = ("%s %s"):format(data.firstname, data.lastname)
        local mods = json.decode(data.vehicle)
        local deformation = json.decode(data.deformation)
        db.data = {
            citizenid = data.owner,
            owner = ownerName,
            vehicle = mods.model,
            props = mods,
            balance = 0,
            deformation = deformation
        }
    end

    return db.data
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

    GarageZone = fileData
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

    CNV = fileData
    local serializedData = ('return {\n%s\n}'):format(getData(fileData))
    SaveResourceFile(GetCurrentResourceName(), 'data/customname.lua', serializedData, -1)
end)

--- exports
exports("Garage", function ()
    return GarageZone
end)
