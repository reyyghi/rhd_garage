local blip = {}
local GarageBlip = {}

function blip.refresh ( data )
    data = data or GarageZone

    for k,v in pairs(GarageBlip) do
        if DoesBlipExist(v) then
            RemoveBlip(v)
        end
    end

    for k, v in pairs(data) do
        if v.blip ~= nil then
            local location = nil
            local points = v.zones.points
            if type(points) == 'table' then
                for i=1, #points do
                    location = points[i]
                end
            end

            GarageBlip[k] = AddBlipForCoord(location.x, location.y, location.z)
            SetBlipSprite(GarageBlip[k], v.blip['type'])
            SetBlipScale(GarageBlip[k], 0.9)
            SetBlipColour(GarageBlip[k], v.blip['color'])
            SetBlipDisplay(GarageBlip[k], 4)
            SetBlipAsShortRange(GarageBlip[k], true)

            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(k)
            EndTextCommandSetBlipName(GarageBlip[k])
        end
    end
end

return blip