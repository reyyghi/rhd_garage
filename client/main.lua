local VehicleShow = nil
local Deformation = require 'modules.deformation'

local function destroyPreview()
    if VehicleShow and DoesEntityExist(VehicleShow) then
        utils.destroyPreviewCam(VehicleShow)
        DeleteVehicle(VehicleShow)
        VehicleShow = nil
    end
end

--- Spawn Vehicle
---@param data GarageVehicleData
local function spawnvehicle ( data )
    local vehData = lib.callback.await('rhd_garage:cb_server:getvehiclePropByPlate', false, data.plate)
    if not vehData then return error('Failed to load vehicle data with number plate ' .. data.plate) end
    local vehEntity = utils.createPlyVeh(vehData.model, data.coords)
    SetVehicleOnGroundProperly(vehEntity)
    if Config.SpawnInVehicle then TaskWarpPedIntoVehicle(cache.ped, vehEntity, -1) end
    SetVehicleEngineHealth(vehEntity, vehData.engine + 0.0)
    SetVehicleBodyHealth(vehEntity, vehData.body + 0.0)
    utils.setFuel(vehEntity, vehData.fuel)
    vehFunc.svp(vehEntity, vehData.mods)
    Deformation.set(vehEntity, vehData.deformation)
    TriggerServerEvent("rhd_garage:server:updateState", { plate = vehData.plate, state = 0, garage = vehData.garage, })
    Entity(vehEntity).state:set('vehlabel', vehData.vehicle_name)
    TriggerEvent("vehiclekeys:client:SetOwner", vehData.plate:trim())
end

--- Garage Action
---@param data GarageVehicleData
local function actionMenu ( data )
    local actionData = {
        id = 'garage_action',
        title = data.vehName:upper(),
        menu = 'garage_menu',
        onBack = destroyPreview,
        onExit = destroyPreview,
        options = {
            {
                title = data.impound and locale('garage.pay_impound') or locale('garage.take_out_veh'),
                icon = data.impound and 'hand-holding-dollar' or 'sign-out-alt',
                iconAnimation = Config.IconAnimation,
                onSelect = function ()
                    if data.impound then
                        utils.createMenu({
                            id = 'pay_methode',
                            title = locale('context.insurance.pay_methode_header'):upper(),
                            onExit = destroyPreview,
                            menu = 'garage_action',
                            options = {
                                {
                                    title = locale('context.insurance.pay_methode_cash_title'):upper(),
                                    icon = 'dollar-sign',
                                    description = locale('context.insurance.pay_methode_cash_desc'),
                                    iconAnimation = Config.IconAnimation,
                                    onSelect = function ()
                                        destroyPreview()
                                        if fw.gm('cash') < data.depotprice then return utils.notify(locale('notify.error.not_enough_cash'), 'error') end
                                        local success = lib.callback.await('rhd_garage:cb_server:removeMoney', false, 'cash', data.depotprice)
                                        if success then
                                            utils.notify(locale('garage.success_pay_impound'), 'success')
                                            return spawnvehicle( data )
                                        end
                                    end
                                },
                                {
                                    title = locale('context.insurance.pay_methode_bank_title'):upper(),
                                    icon = 'fab fa-cc-mastercard',
                                    description = locale('context.insurance.pay_methode_bank_desc'),
                                    iconAnimation = Config.IconAnimation,
                                    onSelect = function ()  
                                        destroyPreview()
                                        if fw.gm('bank') < data.depotprice then return utils.notify(locale('notify.error.not_enough_bank'), 'error') end
                                        local success = lib.callback.await('rhd_garage:cb_server:removeMoney', false, 'bank', data.depotprice)
                                        if success then
                                            utils.notify(locale('garage.success_pay_impound'), 'success')
                                            return spawnvehicle( data )
                                        end
                                    end
                                }
                            }
                        })
                        return
                    end
                    destroyPreview()
                    spawnvehicle( data )
                end
            },
            
        }
    }
    
    if not data.impound then
        if Config.TransferVehicle.enable then
            actionData.options[#actionData.options+1] = {
                title = locale("context.garage.transferveh_title"),
                icon = "exchange-alt",
                iconAnimation = Config.IconAnimation,
                metadata = {
                    price = lib.math.groupdigits(Config.TransferVehicle.price, '.')
                },
                onSelect = function ()
                    destroyPreview()
                    local transferInput = lib.inputDialog(data.vehName:upper(), {
                        { type = 'number', label = 'Player Id', required = true },
                    })

                    if transferInput then
                        local clData = {
                            targetSrc = transferInput[1],
                            plate = data.plate,
                            price = Config.TransferVehicle.price,
                            garage = data.garage
                        }
                        lib.callback('rhd_garage:cb_server:transferVehicle', false, function (success, information)
                            if not success then return
                                utils.notify(information, "error")
                            end

                            utils.notify(information, "success")
                        end, clData)
                    end
                end
            }
        end

        if Config.SwapGarage.enable then
            actionData.options[#actionData.options+1] = {
                title = locale('context.garage.swapgarage'),
                icon = "retweet",
                iconAnimation = Config.IconAnimation,
                metadata = {
                    price = lib.math.groupdigits(Config.SwapGarage.price, '.')
                },
                onSelect = function ()
                    destroyPreview()

                    local garageTable = function ()
                        local result = {}
                        for k, v in pairs(GarageZone) do
                            if k ~= data.garage and not v.impound then
                                result[#result+1] = { value = k }
                            end
                        end
                        return result
                    end

                    local garageInput = lib.inputDialog(data.garage:upper(), {
                        { type = 'select', label = locale('input.garage.swapgarage'), options = garageTable(), required = true},
                    })

                    if garageInput then
                        local vehdata = {
                            plate = data.plate,
                            newgarage = garageInput[1]
                        }

                        if fw.gm('cash') < Config.SwapGarage.price then return utils.notify(locale("notify.error.need_money", lib.math.groupdigits(Config.SwapGarage.price, '.')), 'error') end
                        local success = lib.callback.await('rhd_garage:cb_server:removeMoney', false, 'cash', Config.SwapGarage.price)
                        if not success then return end

                        lib.callback('rhd_garage:cb_server:swapGarage', false, function (success)
                            if not success then return
                                utils.notify(locale("notify.error.swapgarage"), "error")
                            end
    
                            utils.notify(locale('notify.success.swapgarage', vehdata.newgarage), "success")
                        end, vehdata)
                    end
                end
            }
        end

        actionData.options[#actionData.options+1] = {
            title = locale('context.garage.change_veh_name'),
            icon = 'pencil',
            iconAnimation = Config.IconAnimation,
            metadata = {
                price = lib.math.groupdigits(Config.SwapGarage.price, '.')
            },
            onSelect = function ()
                destroyPreview()
                
                local input = lib.inputDialog(data.vehName, {
                    { type = 'input', label = '', placeholder = locale('input.garage.change_veh_name'), required = true, max = 20 },
                })
                
                if input then
                    if fw.gm('cash') < Config.changeNamePrice then return utils.notify(locale('notify.error.not_enough_cash'), 'error') end

                    local success = lib.callback.await('rhd_garage:cb_server:removeMoney', false, 'cash', Config.changeNamePrice)
                    if success then
                        CNV[data.plate] = {
                            name = input[1]
                        }
                        TriggerServerEvent('rhd_garage:server:saveCustomVehicleName', CNV)
                    end
                end
            end
        }
    end

    utils.createMenu(actionData)
end

--- Get available spawn point
---@param point table
---@param targetPed boolean
---@return vector4?
local function getAvailableSP(point, targetPed)
    local results = nil
    local offset = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 2.0, 0.5)

    if type(point) ~= "table" then
        return
    end

    if #point < 1 then
        return
    end
    
    for i=1, #point do
        local c = point[i]
        local sp = vec(c.x, c.y, c.z)
        local dist = #(offset - sp)
        local closestveh = lib.getClosestVehicle(sp, 3.0, true)
        if not targetPed then
            if not closestveh and dist < 3.5 then
                results = vec(c.x, c.y, c.z, c.w)
                break
            end
        else
            if not closestveh then
                results = vec(c.x, c.y, c.z, c.w)
                break
            end
            
        end
    end

    return results
end

--- Open Garage
---@param data GarageVehicleData
local function openMenu ( data )
    if not data then return end
    data.type = data.type or "car"
    
    local menuData = {
        id = 'garage_menu',
        title = data.garage:upper(),
        options = {}
    }

    local vehData = lib.callback.await('rhd_garage:cb_server:getVehicleList', false, data.garage, data.impound, data.shared)
    
    if not vehData then
        return
    end

    for i=1, #vehData do
        local vd = vehData[i]
        local vehProp = vd.vehicle
        local vehModel = vd.model
        local plate = vd.plate
        local vehDeformation = vd.deformation
        local gState = vd.state
        local pName = vd.owner or "Unkown Players"
        local fakeplate = vd.fakeplate
        local engine = vd.engine
        local body = vd.body
        local fuel = vd.fuel
        local dp = vd.depotprice

        local vehName = vd.vehicle_name or fw.gvn( vehModel )
        local customvehName = CNV[plate:trim()] and CNV[plate:trim()].name
        local vehlabel = customvehName or vehName

        local shared_garage = data.shared
        local disabled = false
        local description = ''

        plate = fakeplate and fakeplate:trim() or plate:trim()

        local vehicleClass = GetVehicleClassFromName(vehModel)
        local icon = Config.Icons[vehicleClass] or 'car'
        local ImpoundPrice = dp > 0 and dp or Config.ImpoundPrice[vehicleClass]

        if gState == 0 then
            if vehFunc.govbp(plate) then
                disabled = true
                description = 'STATUS: ' ..  locale('status.out')
            else
                description = locale('garage.impound_price', ImpoundPrice)
            end
        elseif gState == 1 then
            description = 'STATUS: ' ..  locale('status.in')
            if shared_garage then
                description = locale('context.garage.owner_label', pName) .. ' \n' .. 'STATUS: ' .. locale('status.in')
            end
        end

        local vehicleLabel = ('%s [ %s ]'):format(vehlabel, plate)
        menuData.options[#menuData.options+1] = {
            title = vehicleLabel,
            icon = icon,
            disabled = disabled,
            description = description:upper(),
            iconAnimation = Config.IconAnimation,
            metadata = {
                { label = 'Fuel', value = math.floor(fuel) .. '%', progress = math.floor(fuel), colorScheme = utils.getColorLevel(math.floor(fuel))},
                { label = 'Body', value = math.floor(body / 10) .. '%', progress = math.floor(body / 10), colorScheme = utils.getColorLevel(math.floor(body / 10))},
                { label = 'Engine', value = math.floor(engine/ 10) .. '%', progress = math.floor(engine / 10), colorScheme = utils.getColorLevel(math.floor(engine / 10))}
            },
            onSelect = function ()
                local defaultcoords = vec(GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 2.0, 0.5), GetEntityHeading(cache.ped)+90)

                if data.spawnpoint then
                    defaultcoords = getAvailableSP(data.spawnpoint, data.targetped) --[[@as vector4]]
                end

                if not defaultcoords then
                    return utils.notify(locale('notify.error.no_parking_spot'), 'error', 8000)
                end
                
                local vehInArea = lib.getClosestVehicle(defaultcoords.xyz)
                if DoesEntityExist(vehInArea) then return utils.notify(locale('notify.error.no_parking_spot'), 'error') end

                VehicleShow = utils.createPlyVeh(vehModel, defaultcoords)
                FreezeEntityPosition(VehicleShow, true)
                SetVehicleDoorsLocked(VehicleShow, 2)
                utils.createPreviewCam(VehicleShow)

                if vehProp and next(vehProp) then
                    vehFunc.svp(VehicleShow, vehProp)
                end

                actionMenu({
                    prop = vehProp,
                    engine = engine,
                    fuel = fuel,
                    body = body,
                    model = vehModel,
                    plate = plate,
                    coords = defaultcoords,
                    garage = data.garage,
                    vehName = vehicleLabel,
                    vehicle_name = vehlabel,
                    impound = data.impound,
                    shared = data.shared,
                    deformation = vehDeformation,
                    depotprice = ImpoundPrice
                })
            end,
        }
    end

    if #menuData.options < 1 then 
        menuData.options[#menuData.options+1] = {
            title = locale('garage.no_vehicles'):upper(),
            disabled = true
        }
    end

    utils.createMenu(menuData)
end

--- Store Vehicle To Garage
---@param data GarageVehicleData
local function storeVeh ( data )
    local myCoords = GetEntityCoords(cache.ped)
    local vehicle = cache.vehicle or lib.getClosestVehicle(myCoords)

    local vehicleClass = GetVehicleClass(vehicle)
    local vehicleType = utils.getCategoryByClass(vehicleClass)

    if not vehicle then return
        utils.notify(locale('notify.error.not_veh_exist'), 'error')
    end

    if not lib.table.contains(data.type, vehicleType) then return
        utils.notify(locale('notify.info.invalid_veh_classs', data.garage))
    end

    local prop = vehFunc.gvp(vehicle)
    local plate = prop.plate:trim()
    local shared = data.shared
    local deformation = Deformation.get(vehicle)
    local fuel = utils.getFuel(vehicle)
    local engine = GetVehicleEngineHealth(vehicle)
    local body = GetVehicleBodyHealth(vehicle)

    local isOwned = lib.callback.await('rhd_garage:cb_server:getvehowner', false, plate, shared, {
        mods = prop,
        deformation = deformation,
        fuel =  fuel,
        engine = engine,
        body = body,
        vehicle_name = Entity(vehicle).state.vehlabel
    })

    if not isOwned then return
        utils.notify(locale('notify.error.not_owned'), 'error')
    end

    if cache.vehicle and cache.seat == -1 then
        TaskLeaveAnyVehicle(cache.ped, true, 0)
        Wait(1000)
    end

    if DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
        TriggerServerEvent('rhd_garage:server:updateState', {plate = plate, state = 1, garage = data.garage})
        utils.notify(locale('notify.success.store_veh'), 'success')
    end
end

--- exports 
exports('openMenu', openMenu)
exports('storeVehicle', storeVeh)