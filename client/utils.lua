Utils = {}

Utils.notif = function ( txt, type )
    return lib.notify({
        title = 'RHD GARAGE',
        description = txt,
        type = type
    })
end

Utils.getPlate = function ( number )
    if not number then return nil end
    return (string.gsub(number, '^%s*(.-)%s*$', '%1'))
end

Utils.createPlyVeh = function ( model, coords, cb, network )
    network = network == nil and true or network
    lib.requestModel(model)
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, network, false)
    if network then
        local id = NetworkGetNetworkIdFromEntity(veh)
        SetNetworkIdCanMigrate(id, true)
        SetEntityAsMissionEntity(veh, true, true)
    end
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehRadioStation(veh, 'OFF')
    SetModelAsNoLongerNeeded(model)
    if cb then cb(veh) else return veh end
end

Utils.VehicleCheck = function ( VehType, Vehicle )
    local VehClass = GetVehicleClass(Vehicle)
    if VehType == 'car' then
        if VehClass ~= 14 and VehClass ~= 15 and VehClass ~= 16 then return true end
    elseif VehType == 'boat' then
        if VehClass == 14 then return true end
    elseif VehType == 'planes' then
        if VehClass == 16 then return true end
    elseif VehType == 'helicopter' then
        if VehClass == 15 then return true end
    end
    return false
end

Utils.GangCheck = function ( data )
    local configGang = Config.Garages[data.garage]['gang']
    local plyJob = Framework.playerGang()
    if type(configGang) == 'table' then
        for job, grade in pairs(configGang) do      
            if type(job.grade) == 'table' then
                job.grade = job.grade.level
            end
            if plyJob.name == job and plyJob.grade >= grade then
                return true
            end
        end
    elseif type(configGang) == 'string' then
        if plyJob.name == configGang then
            return true
        end
    end
    return false
end

Utils.JobCheck = function ( data )
    local configJob = Config.Garages[data.garage]['job']
    local plyJob = Framework.playerJob()
    if type(configJob) == 'table' then
        for job, grade in pairs(configJob) do         
            if type(job.grade) == 'table' then
                job.grade = job.grade.level
            end
            if plyJob.name == job and plyJob.grade >= grade then
                return true
            end
        end
    elseif type(configJob) == 'string' then
        if plyJob.name == configJob then
            return true
        end
    end
    return false
end

Utils.createGarageZone = function ( data )
    local zoneOptions = {
        coords = data.coords,
        radius = 2,
        debug = data.debug or false,
    }
    if data.inside then
        zoneOptions.inside = data.inside
    end
    if data.exit then
        zoneOptions.onExit = data.exit
    end
    if data.enter then
        zoneOptions.onEnter = data.enter
    end
    return lib.zones.sphere(zoneOptions)
end

Utils.drawtext = function ( type, txt, icon )
    if type == 'show' then
        return lib.showTextUI(txt,{
            position = "left-center",
            icon = icon or '',
            style = {
                borderRadius= 5,
                backgroundColor = '#0985e3f8',
                color = 'white'
            }
        })
    elseif type == 'hide' then
        return lib.hideTextUI()
    end
end

Utils.createMenu = function ( data )
    lib.registerContext(data)
    lib.showContext(data.id)
end

Utils.createGarageRadial = function ( data )
    if Config.RadialMenu == 'qb-radialmenu' then return Framework.addRadial( data ) end
    if data.gType == 'garage' then
        lib.addRadialItem({
            id = 'open_garage',
            icon = 'warehouse',
            label = locale('rhd_garage:open_garage'),
            onSelect = function ()
                if cache.vehicle then return end
                Garage.openMenu( data )
            end
        })

        lib.addRadialItem({
            id = 'store_vehicle',
            icon = 'parking',
            label = locale('rhd_garage:store_vehicle'),
            onSelect = function ()
                local plyVeh = cache.vehicle
                if not cache.vehicle then
                    plyVeh = lib.getClosestVehicle(GetEntityCoords(cache.ped))
                end

                if not Utils.VehicleCheck( data.vType, plyVeh ) then return Utils.notif(locale('rhd_garage:invalid_vehicle_class', string.lower(data.garage))) end

                if DoesEntityExist(plyVeh) then
                    if cache.vehicle then
                        if cache.seat ~= -1 then return end
                        TaskLeaveAnyVehicle(cache.ped, true, 0)
                        Wait(1000)
                    end
                    Garage.storeVeh({
                        vehicle = plyVeh,
                        garage = data.garage,
                    })
                else
                    Utils.notif(locale('rhd_garage:not_vehicle_exist'), 'error')
                end
            end
        })
    elseif data.gType == 'impound' then
        lib.addRadialItem({
            id = 'open_impound',
            icon = 'warehouse',
            label = locale('rhd_garage:access_impound'),
            onSelect = function ()
                if cache.vehicle then return end
                Garage.openMenu( data )
            end
        })
    elseif data.gType == 'PoliceImpound' then
        lib.addRadialItem({
            id = 'police_impound',
            icon = 'warehouse',
            label = locale('rhd_garage:policeimpound_radial_impound'),
            onSelect = function ()
                if cache.vehicle then return end
                PoliceImpound.openGarage( data )
            end
        })
    end
end

Utils.removeRadial = function ( type )
    if Config.RadialMenu == 'qb-radialmenu' then return Framework.removeRadial( type ) end
    if type == 'garage' then
        lib.removeRadialItem('open_garage')
        lib.removeRadialItem('store_vehicle')
    elseif type == 'impound' then
        lib.removeRadialItem('open_impound')
    elseif type == 'PoliceImpound' then
        lib.removeRadialItem('police_impound')
    end
end
