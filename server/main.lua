IsQB = Framework.qb()

local Utils = require 'modules.utils'

--- callback
lib.callback.register('rhd_garage:cb_server:removeMoney', function(src, type, amount)
    return Framework.server.removeMoney(src, type, amount)
end)

lib.callback.register('rhd_garage:cb_server:createVehicle', function (_, vehicleData )
    local props = {}
    local deformation = {}
    
    local veh = CreateVehicleServerSetter(vehicleData.model, vehicleData.vehtype, vehicleData.coords.x, vehicleData.coords.y, vehicleData.coords.z, vehicleData.coords.w)
    
    while not DoesEntityExist(veh) do Wait(10) end
    while GetVehicleNumberPlateText(veh) == '' do Wait(10) end
    while NetworkGetEntityOwner(veh) == -1 do Wait(10) end
    SetVehicleNumberPlateText(veh, vehicleData.plate)
    
    local netId, owner = NetworkGetNetworkIdFromEntity(veh), NetworkGetEntityOwner(veh)
    local result = MySQL.query.await(DBFormat.getParameters("createvehicle"), DBFormat.getValue("createvehicle", vehicleData.plate))
    if result then print(json.encode(result[1])) props = result[1][DBFormat.column.properties] deformation = result[1].deformation end
    TriggerClientEvent('ox_lib:setVehicleProperties', owner, netId, json.decode(props))
    return { netId = netId, props = json.decode(props), plate = vehicleData.plate, deformation = json.decode(deformation) }
end)

lib.callback.register('rhd_garage:cb_server:getvehowner', function (src, plate, shared)
    local identifier = Framework.server.getIdentifier(src)
    local garageType = shared and "shared" or "normal"
    return MySQL.single.await(DBFormat.getParameters("getowner", garageType), DBFormat.getValue("getowner", garageType, identifier, plate))
end)


lib.callback.register('rhd_garage:cb_server:getVehicleList', function(src, garage, impound, shared)
    local VehicleResult = {}
    local garageType = impound and "impound" or shared and "shared" or "normal"
    local identifier = Framework.server.getIdentifier(src)
    local result = MySQL.query.await(DBFormat.getParameters("vehiclelist", garageType), DBFormat.getValue("vehiclelist", garageType, garage, identifier))

    if result and next(result) then
        for k, v in pairs(result) do
            local charinfo = IsQB and json.decode(v.charinfo) or {}
            local vehicles = json.decode(IsQB and v.mods or v.vehicle)
            local deformation = json.decode(v.deformation)
            local state = IsQB and v.state or v.stored or 0
            local model = IsQB and v.vehicle or vehicles.model
            local plate = v.plate
            local depotprice = IsQB and v.depotprice or 0
            local fakeplate = IsQB and v.fakeplate or nil
            local ownername = ("%s %s"):format(IsQB and charinfo.firstname or v.firstname, IsQB and charinfo.lastname or v.lastname)
            
            VehicleResult[#VehicleResult+1] = {
                vehicle = vehicles,
                state = state,
                model = model,
                plate = plate,
                fakeplate = fakeplate,
                owner = ownername,
                depotprice = depotprice,
                deformation = deformation
            }
        end
    end
    return VehicleResult
end)

lib.callback.register('rhd_garage:cb_server:getvehicledatabyplate', function (_, plate)
    local data = MySQL.single.await(DBFormat.getParameters("vehicledata"), DBFormat.getValue("vehicledata", plate))
    if not data then return {} end
    local mods = json.decode(data[DBFormat.column.properties])
    local charinfo = IsQB and json.decode(data.charinfo) or {}
    local deformation = json.decode(data.deformation)
    local balance = IsQB and data.balance or 0
    local ownername = ("%s %s"):format(IsQB and charinfo.firstname or data.firstname, IsQB and charinfo.lastname or data.lastname)
    local vehicle = IsQB and data.vehicle or mods.model

    return {
        citizenid = data[DBFormat.column.owner],
        owner = ownername,
        vehicle = vehicle,
        props = mods,
        balance = balance,
        deformation = deformation
    }
end)

lib.callback.register("rhd_garage:cb_server:swapGarage", function (source, clientData)
    local identifier = Framework.server.getIdentifier(source)
    local changed = MySQL.update.await(DBFormat.getParameters("swapgarage"), DBFormat.getValue("swapgarage", clientData.newgarage, identifier, clientData.plate))
    return changed > 0
end)

lib.callback.register("rhd_garage:cb_server:transferVehicle", function (src, clientData)
    local TargetIdentifier = Framework.server.getIdentifier(clientData.targetSrc)
    local myIdentifier = Framework.server.getIdentifier(src)
    if not TargetIdentifier then return false, locale("rhd_garage:transferveh_plyoffline", clientData.targetSrc) end
    if TargetIdentifier == myIdentifier then return false, locale("rhd_garage:transferveh_cannot_transfer") end
    if not Framework.server.removeMoney(src, "cash", clientData.price) then return false, locale("rhd_garage:transferveh_no_money") end
    local changed = MySQL.update.await(DBFormat.getParameters("transfervehicle"), DBFormat.getValue("transfervehicle", TargetIdentifier, clientData.plate, myIdentifier))
    local success = changed > 0
    if success then Utils.ServerNotify(clientData.targetSrc, locale("rhd_garage:transferveh_success_target", Framework.server.getName(src), clientData.garage), "success") end
    return changed > 0, locale("rhd_garage:transferveh_success_src", Framework.server.getName(clientData.targetSrc))
end)

--- Event
RegisterNetEvent("rhd_garage:server:updateState", function ( data )
    local prop = data.prop
    local deformation = data.deformation
    local state = data.state
    local garage = data.garage
    local plate = data.plate
    if GetInvokingResource() then return end
    MySQL.update(DBFormat.getParameters("state_garage"), DBFormat.getValue("state_garage", state, json.encode(prop), garage,  json.encode(deformation), plate))
end)

RegisterNetEvent("rhd_garage:server:saveGarageZone", function(fileData)
    if GetInvokingResource() then return end
    if type(fileData) ~= "table" or type(fileData) == "nil" then return end
    return Storage.save.garage(fileData)
end)

RegisterNetEvent("rhd_garage:server:saveCustomVehicleName", function (fileData)
    if GetInvokingResource() then return end
    if type(fileData) ~= "table" or type(fileData) == "nil" then return end
    return Storage.save.vehname(fileData)
end)

--- exports
exports("Garage", function ()
    return GarageZone
end)
