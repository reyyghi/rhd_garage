if Config.RadialMenu ~= "rhd" then return end

radFunc = {}
function radFunc.create(data)
    return exports.rhd_radialmenu:addRadialItem({
        id = data.id,
        label = data.label,
        icon = data.icon,
        action = function ()
            exports.rhd_garage:openMenu({
                garage = data.label,
                impound = data.garage.impound,
                shared = data.garage.shared,
                type = data.garage.type
            })
        end
    })
end

function radFunc.remove(id)
    return exports.rhd_radialmenu:removeRadialItem(id)
end
