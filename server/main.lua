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
    return fw.gpvbp(plate)
end)

lib.callback.register("rhd_garage:cb_server:swapGarage", function (source, clientData)
    return fw.svg(clientData.newgarage, clientData.plate)
end)

lib.callback.register("rhd_garage:cb_server:transferVehicle", function (src, clientData)
    if src == clientData.targetSrc then
        return false, locale("rhd_garage:transferveh_cannot_transfer")
    end

    local tid = clientData.targetSrc
    local mp = fw.gp(src)
    local tp = fw.gp(tid)
    if not mp then return end
    if not tp then return false, locale("rhd_garage:transferveh_plyoffline", clientData.targetSrc) end
    if fw.rm(src, "cash", clientData.price) then
        return false, locale("rhd_garage:transferveh_no_money")
    end
    
    local success = fw.uvo({
        citizenid = mp.citizenid
    }, {
        citizenid = tp.citizenid,
        license = tp.license
    }, clientData.plate)

    if success then Utils.ServerNotify(tid, locale("rhd_garage:transferveh_success_target", fw.gn(src), clientData.garage), "success") end
    return success, locale("rhd_garage:transferveh_success_src", fw.gn(tid))
end)

-- lib.callback.register('rhd_garage:cb_server:getvehdataForPhone', function(src)
--     return GetPlayerVehiclesForPhone(src)
-- end)

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
