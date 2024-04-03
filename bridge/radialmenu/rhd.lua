if Config.RadialMenu ~= "rhd" then return end

radFunc = {}

function radFunc.create(data)
    exports.rhd_radialmenu:addRadialItem({
        id = data.id,
        label = data.label,
        icon = data.icon,
        action = function ()
            if data.id == "open_garage" and not cache.vehicle then
                exports.rhd_garage:openMenu(data.args)
            elseif data.id == "store_veh" then
                exports.rhd_garage:storeVehicle(data.args)
            end
        end
    })
end

function radFunc.remove(id)
    exports.rhd_radialmenu:removeRadialItem(id)
end
