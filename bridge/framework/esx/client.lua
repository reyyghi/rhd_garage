if not Framework.esx() then return end

local esx = exports.es_extended:getSharedObject()

Framework.playerJob = function ()
    return esx.GetPlayerData().job
end
Framework.playerGang = function ()
    return esx.GetPlayerData().job
end

Framework.getVehName = function ( model )
    return GetDisplayNameFromVehicleModel( model )
end

Framework.getName = function()
    return ("%s"):format(LocalPlayer.state.name)
end

Framework.getMoney = function ( type )
    local amount = 0
    local plyMoney = esx.GetPlayerData().accounts

    type = type == "cash" and "money" or type
    for i=1, #plyMoney do
        if plyMoney[i].name == type:lower() then
            amount = plyMoney[i].money
        end
    end

    return amount
end
