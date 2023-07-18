if not Framework.esx() then return end

local esx = exports.es_extended:getSharedObject()

Framework.playerJob = function ()
    return esx.GetPlayerData().job
end
Framework.playerGang = function ()
    return Framework.playerJob()
end

Framework.playerName = LocalPlayer.state.name

Framework.getVehName = function ( model )
    return GetDisplayNameFromVehicleModel( model )
end

Framework.isPlyVeh = function ( plate )
    local plyVeh = lib.callback.await('rhd_garage:cb:getVehOwner', false, plate)
    return plyVeh
end

Framework.getdbVehicle = function ( garage )
    local dataVeh = lib.callback.await('rhd_garage:cb:getVehicleList', false, garage)
    return dataVeh
end

Framework.updateState = function ( data )
    TriggerServerEvent('rhd_garage:server:updateVehState', data)
end

Framework.getMoney = function ( type )
    local amount = 0
    local cash, bank
    local plyMoney = esx.GetPlayerData().accounts

    for i=1, #plyMoney do
        if plyMoney[i].name == 'money' then
            cash = plyMoney[i].money
        elseif plyMoney[i].name == 'bank' then
            bank = plyMoney[i].money
        end
    end

    if type == 'cash' then
        amount = cash
    elseif type == 'bank' then
        amount = bank
    end

    return amount
end

Framework.removeMoney = function ( type, amount )
    return lib.callback.await('rhd_garage:cb:removeMoney', false, type, amount)
end
