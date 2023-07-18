CreateThread(function()
    for k, v in pairs(Config.Garages) do
        if v.blip ~= nil then
            local location = nil
            if type(v.location) == 'table' then
                for i=1, #v.location do
                    location = v.location[i]
                end
            elseif type(v.location) == 'vector4' then
                location = v.location
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
end)