---@class NamedVehicleList
local NVL = {
    boat = {
        'jetmax',
        'dinghy',
        'seashark',
        'tug'
    },
    planes = {
        'luxor2',
        'shamal',
        'nimbus',
        'vestra'
    },
    helicopter = {
        'volatus',
        'swift2',
        'cargobob',
    },
    car = {
        'kuruma',
        'guardian',
        'firetruk',
        'pbus',
        'flatbed',
        'ambulance',
    },
    motorcycle = {
        'sanchez',
        'bagger',
        'wolfsbane'
    },
    cycles = {
        'bmx',
        'cruiser',
        'tribike'
    },
}

local spawnPoint = {}
local vehCreated = {}
local curVehicle = nil
local busy = false
local glm = require "glm"
local glm_polygon_contains = glm.polygon.contains
local debugzone = require 'modules.debugzone'
local function deletePV(pos)

    if pos and type(pos) == 'number' then
        if vehCreated[pos] then
            DeleteEntity(vehCreated[pos])
            table.remove(vehCreated, pos)
        end
        return
    end

    for i=1, #vehCreated do
        local entity = vehCreated[i]
        DeleteEntity(entity)
    end
    vehCreated = {}
end

local function CancelPlacement()
    busy = false
    deletePV()
    DeleteVehicle(curVehicle)
    curVehicle = nil
end

---@param table vector3[]
local function tovec3(table)
    local results = {}
    for i=1, #table do
        local c = table[i]
        results[#results+1] = vec3(c.x, c.y, c.z)
    end
    return results
end

---@param coords vector3
local function closestPV(coords)
    local results = false
    for i=1, #vehCreated do
        local entity = vehCreated[i]
        local vc = GetEntityCoords(entity)
        local dist = #(coords - vc)
        if dist < 3 then
            results = true
            break
        end
    end
    return results
end

---@param model string|integer
---@param coords vector4
local function createPV(model, coords)
    local vm = model
    lib.requestModel(vm)
    local pv = CreateVehicle(vm, coords.x, coords.y, coords.z, coords.w, false, false)
    SetVehicleDoorsLocked(pv, 2)
    SetEntityAlpha(pv, 150, true)
    SetEntityInvincible(pv, true)
    SetEntityCollision(pv, false, false)
    FreezeEntityPosition(pv, true)
    return pv
end

--- Create Spawn Points
---@param zone OxZone
---@param required boolean
---@param existingPoint table<string, vector3[]|string[]>
---@param vehicleTypes string[]
---@return promise?
function spawnPoint.create(zone, required, existingPoint, vehicleTypes)
    if not vehicleTypes or type(vehicleTypes) ~= 'table' then return end
    if not zone then return end
    if busy then return end

    local typeIndex = 1
    local vehIndex = 1
    local vehType = vehicleTypes[typeIndex]
    local vehicle = NVL[vehType][vehIndex]
    local points = tovec3(zone.points)
    local polygon = glm.polygon.new(points)

    local text = [[
    [X]: Close
    [Enter]: Confirm
    [Spacebar]: Add Points
    [Arrow Up/Down]: Height
    [Arrow Right/Left]: Rotate Vehicle
    [Backspace]: Delete Point
    [Mouse Scroll Up/Down]: Change Type (Current Type: %s)
    [LShift + Mouse Scroll Up/Down]: Change Model (Current Model: %s)
    ]]

    utils.drawtext('show', text:format(vehType, vehicle))
    lib.requestModel(vehicle, 1500)
    curVehicle = createPV(vehicle, vec(1.0, 1.0, 1.0, 0))

    local vc = {}
    local svp = {}
    local heading = 0.0
    local prefixZ = 0.0
    local sp = {v = {}, c = {}}

    if existingPoint and #existingPoint.c > 0 then
        for i=1, #existingPoint.c do
            local coords = existingPoint.c[i]
            local vehModel = existingPoint.v[i] or vehicle
            local pv = createPV(vehModel, coords)
            vc[i] = coords
            svp[i] = vehModel
            vehCreated[i] = pv
        end
    end

    local results = promise.new()
    CreateThread(function()
        busy = true

        while busy do
            local hit, coords, inwater, wcoords = utils.raycastCam(20.0)

            CurrentCoords = GetEntityCoords(curVehicle)
            
            local inZone = glm_polygon_contains(polygon, CurrentCoords, zone.thickness / 4)
            local debugColor = inZone and {r = 10, g = 244, b = 115, a = 50} or {r = 240, g = 5, b = 5, a = 50}
            debugzone.start(polygon, zone.thickness, debugColor)

            if hit == 1 and not inwater then
                SetEntityCoords(curVehicle, coords.x, coords.y, coords.z + prefixZ, false, false, false, false)
            elseif inwater then
                SetEntityCoords(curVehicle, wcoords.x, wcoords.y, wcoords.z + prefixZ, false, false, false, false)
            end

            DisableControlAction(0, 174, true)
            DisableControlAction(0, 175, true)
            DisableControlAction(0, 73, true)
            DisableControlAction(0, 176, true)
            DisableControlAction(0, 14, true)
            DisableControlAction(0, 15, true)
            DisableControlAction(0, 172, true)
            DisableControlAction(0, 173, true)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 194, true)
            
            if IsDisabledControlPressed(0, 174) then
                heading = heading + 0.5
                if heading > 360 then heading = 0.0 end
            end
    
            if IsDisabledControlPressed(0, 175) then
                heading = heading - 0.5
                if heading < 0 then heading = 360.0 end
            end

            if IsDisabledControlJustPressed(0, 172) then
                prefixZ += 0.1
            end
    
            if IsDisabledControlJustPressed(0, 173) then
                prefixZ -= 0.1
            end

            if IsDisabledControlJustPressed(0, 15) then
                if IsDisabledControlPressed(0, 21) then
                    local newIndex = vehIndex+1
                    local newModel = NVL[vehType][newIndex]
                    if newModel then
                        DeleteEntity(curVehicle)
                        local veh = createPV(newModel, vec(1.0, 1.0, 1.0, 0))
                        curVehicle = veh
                        vehIndex = newIndex
                        vehicle = newModel
                    end
                else
                    local newIndex = typeIndex + 1
                    local newType = vehicleTypes[newIndex]
                    if newType and NVL[newType] then
                        local newModel = NVL[newType][1]
                        DeleteEntity(curVehicle)
                        local veh = createPV(newModel, vec(1.0, 1.0, 1.0, 0))
                        curVehicle = veh
                        vehType = newType
                        typeIndex = newIndex
                        vehIndex = 1
                        vehicle = newModel
                    end
                end
                utils.drawtext('show', text:format(vehType, vehicle))
            end

            if IsDisabledControlJustPressed(0, 14) then
                if IsDisabledControlPressed(0, 21) then
                    local newIndex = vehIndex-1
                    local newModel = NVL[vehType][newIndex]
                    if newModel then
                        DeleteEntity(curVehicle)
                        local veh = createPV(newModel, vec(1.0, 1.0, 1.0, 0))
                        curVehicle = veh
                        vehIndex = newIndex
                        vehicle = newModel
                    end
                else
                    local newIndex = typeIndex - 1
                    local newType = vehicleTypes[newIndex]
                    if newType and NVL[newType] then
                        local newModel = NVL[newType][1]
                        DeleteEntity(curVehicle)
                        local veh = createPV(newModel, vec(1.0, 1.0, 1.0, 0))
                        curVehicle = veh
                        vehType = newType
                        typeIndex = newIndex
                        vehIndex = 1
                        vehicle = newModel
                    end
                end
                utils.drawtext('show', text:format(vehType, vehicle))
            end
            
            if IsDisabledControlJustPressed(0, 194) then
                if #vc > 0 then
                    local lastPos = #vc
                    deletePV(lastPos)
                    table.remove(svp, lastPos)
                    table.remove(vc, lastPos)
                    utils.notify('Spawn point ' .. lastPos .. ' has been removed.')
                else
                    utils.notify('No spawn point has been created yet!', 'error', 8000)
                end
            end

            if IsDisabledControlJustPressed(0, 73) then
                CancelPlacement()
                results:resolve(false)
                utils.notify('Spawn point creation cancelled!', 'error', 8000)
            end

            SetEntityHeading(curVehicle, heading)

            if IsDisabledControlJustPressed(0, 176) then
                if required and #vc < 1 then
                    utils.notify("You must create at least x1 spawn points", "error", 8000)
                else
                    if #vc > 0 then
                        sp.c = vc
                        sp.v = svp
                    else
                        sp = nil
                    end
                    results:resolve(sp or false)
                    CancelPlacement()
                end
            end

            if IsDisabledControlJustPressed(0, 22) then
                if hit == 1 then
                    local closestVeh = closestPV(CurrentCoords.xyz)

                    if closestVeh then
                        utils.notify("Look for another place", "error", 8000)
                        goto next
                    end

                    if inZone then
                        local rc = vec4(CurrentCoords.x, CurrentCoords.y, CurrentCoords.z, heading)
                        local vm = NVL[vehType][vehIndex]
                        local pv = createPV(vm, rc)
                        
                        vc[#vc+1] = rc
                        svp[#vc] = vm
                        
                        vehCreated[#vehCreated+1] = pv
                        utils.notify("location successfully created " .. #vc, "success", 8000)
                    else
                        utils.notify("cannot add spawn points outside the zone", "error", 8000)
                    end

                    ::next::
                end
            end
            Wait(1)
        end
        utils.drawtext('hide')
    end)

    return Citizen.Await(results)
end

AddEventHandler('onResourceStop', function(resource)
   if resource == GetCurrentResourceName() then
    lib.hideTextUI()
    DeleteVehicle(curVehicle)
    for i=1, #vehCreated do
        local entity = vehCreated[i]
        DeleteEntity(entity)
    end
   end
end)

return spawnPoint