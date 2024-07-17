RegisterNetEvent('rhd_garage:server:buyVehicle', function(vehData)
    if GetInvokingResource() then return end
    local citizenid, license = fw.gi(source, true)
    vehData.citizenid = citizenid
    vehData.license = license
    if fw.rm(source, 'bank', vehData.price) then
        fw.inv(vehData)
        utils.notify(source, locale('notify.success.vehicleshop.buyVehicle', vehData.label, vehData.price), 'success', 8000)
    end
end)