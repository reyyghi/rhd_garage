local Utils = lib.load('modules.utils')

--- callback
lib.callback.register('rhd_garage:cb_server:removeMoney', function(src, type, amount)
    return fw.rm(src, type, amount)
end)

lib.callback.register('rhd_garage:cb_server:createVehicle', function (source, vehicleData )
    local props = {}
    local deformation = {}
    
    local veh = CreateVehicleServerSetter(vehicleData.model, vehicleData.vehtype, vehicleData.coords.x, vehicleData.coords.y, vehicleData.coords.z, vehicleData.coords.w)
    Wait(100)
    
    while not DoesEntityExist(veh) do Wait(10) end
    while GetVehicleNumberPlateText(veh) == '' do Wait(10) end
    while NetworkGetEntityOwner(veh) == -1 do Wait(10) end
    SetVehicleNumberPlateText(veh, vehicleData.plate)
    
    local netId, owner = NetworkGetNetworkIdFromEntity(veh), NetworkGetEntityOwner(veh)
    local result = fw.gmdbp(vehicleData.plate)
    props = result.prop deformation = result.deformation
    lib.callback.await('rhd_garage:cb_client:vehicleSpawned', owner, netId, props)
    return { netId = netId, props = props, plate = vehicleData.plate, deformation = deformation }
end)

lib.callback.register('rhd_garage:cb_server:getvehowner', function (src, plate, shared, pleaseUpdate)
    return fw.gvobp(src, plate, {
        owner = shared
    }, pleaseUpdate)
end)


lib.callback.register('rhd_garage:cb_server:getVehicleList', function(src, garage, impound, shared)
    return fw.gpvbg(src, garage, {
        impound = impound,
        shared = shared
    })
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

lib.callback.register('rhd_garage:cb_server:getvehdataForPhone', function(src)
    return GetPlayerVehiclesForPhone(src)
end)

--- Event
RegisterNetEvent("rhd_garage:server:updateState", function ( data )
    if GetInvokingResource() then return end
    fw.uvs(data.plate, data.state, data.garage)
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
