local blip = {}

function blip.refresh ( data )
    data = data or GarageZone
    for k, v in pairs(data) do
        if v.blip ~= nil then
            local location = nil
            local points = v.zones.points
            if type(points) == 'table' then
                for i=1, #points do
                    location = points[i]
                end
            end

            local GarageBlip = AddBlipForCoord(location.x, location.y, location.z)
            SetBlipSprite(GarageBlip, v.blip['type'])
            SetBlipScale(GarageBlip, 0.9)
            SetBlipColour(GarageBlip, v.blip['color'])
            SetBlipDisplay(GarageBlip, 4)
            SetBlipAsShortRange(GarageBlip, true)

            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(k)
            EndTextCommandSetBlipName(GarageBlip)
        end
    end
end

return blip