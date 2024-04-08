local spawnPoint = {}

local vehicleList = {
    'kuruma',
    'guardian',
}

local curVehicle = nil
local busy = false
local glm = require "glm"

local function CancelPlacement()
    DeleteVehicle(curVehicle)
    busy = false
    curVehicle = nil
end

local RotationToDirection = function(rot)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosOfRotX = math.abs(math.cos(rotX))
    return vector3(-math.sin(rotZ) * cosOfRotX, math.cos(rotZ) * cosOfRotX, math.sin(rotX))
end

local function RayCastGamePlayCamera(distance)
    local camRot = GetGameplayCamRot()
    local camPos = GetGameplayCamCoord()
    local dir = RotationToDirection(camRot)
    local dest = camPos + (dir * distance)
    local ray = StartShapeTestRay(camPos, dest, 17, -1, 0)
    local _, hit, endPos, surfaceNormal, entityHit = GetShapeTestResult(ray)
    if hit == 0 then endPos = dest end
    return hit, endPos, entityHit, surfaceNormal
end

function spawnPoint.create(zone, required)
    if not zone then return end
    if busy then return end
    local vehIndex = 1
    local vehicle = vehicleList[vehIndex]
    local polygon = glm.polygon.new(zone.points)

    local text = [[
    [X]: Cancel
    [Enter]: Confirm
    [Arrow Up/Down]: Height
    [Arrow Right/Left]: Rotate Vehicle
    [Mouse Scroll Up/Down]: Change Vehicle
    ]]

    lib.showTextUI(text)
    lib.requestModel(vehicle, 1500)
    curVehicle = CreateVehicle(vehicle, 1.0, 1.0, 1.0, 0, false, false)
    SetEntityAlpha(curVehicle, 150, true)
    SetEntityCollision(curVehicle, false, false)
    FreezeEntityPosition(curVehicle, true)

    local vc = {}
    local heading = 0.0
    local prefixZ = 0.0

    local results = promise.new()
    CreateThread(function()
        busy = true

        while busy do
            local hit, coords, entity = RayCastGamePlayCamera(20.0)
            CurrentCoords = GetEntityCoords(curVehicle)
            
            local inZone = glm.polygon.contains(polygon, CurrentCoords, zone.thickness / 4)
            local outlineColour = inZone and {255, 255, 255, 255} or {240, 5, 5, 1}
            SetEntityDrawOutline(curVehicle, true)
            SetEntityDrawOutlineColor(outlineColour[1], outlineColour[2], outlineColour[3], outlineColour[4])

            if hit == 1 then
                SetEntityCoords(curVehicle, coords.x, coords.y, coords.z + prefixZ)
            end

            DisableControlAction(0, 174, true)
            DisableControlAction(0, 175, true)
            DisableControlAction(0, 73, true)
            DisableControlAction(0, 176, true)
            DisableControlAction(0, 14, true)
            DisableControlAction(0, 15, true)
            DisableControlAction(0, 172, true)
            DisableControlAction(0, 173, true)
            
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

            if IsDisabledControlJustPressed(0, 14) then
                local newIndex = vehIndex+1
                local newModel = vehicleList[newIndex]
                if newModel then
                    DeleteEntity(curVehicle)
                    lib.requestModel(newModel)
                    local veh = CreateVehicle(newModel, 1.0, 1.0, 1.0, 0, false, false)
                    SetEntityAlpha(veh, 150, true)
                    SetEntityCollision(veh, false, false)
                    FreezeEntityPosition(veh, true)
                    curVehicle = veh
                    vehIndex = newIndex
                    object = newModel
                end
            end

            if IsDisabledControlJustPressed(0, 15) then
                local newIndex = vehIndex-1

                if newIndex >= 1 then
                    local newModel = vehicleList[newIndex]
                    if newModel then
                        DeleteEntity(curVehicle)
                        lib.requestModel(newModel)
                        local veh = CreateVehicle(newModel, 1.0, 1.0, 1.0, 0, false, false)
                        SetEntityAlpha(veh, 150, true)
                        SetEntityCollision(veh, false, false)
                        FreezeEntityPosition(veh, true)
                        curVehicle = veh
                        vehIndex = newIndex
                        object = newModel
                    end
                end
            end
            
            if IsDisabledControlJustPressed(0, 73) then
                if required and #vc < 1 then
                    utils.notify("You must create at least x1 spawn points", "error", 8000)
                else
                    CancelPlacement()
                end
            end

            SetEntityHeading(curVehicle, heading)

            if IsDisabledControlJustPressed(0, 176) then
                if hit == 1 then

                    if inZone then
                        vc[#vc+1] = vec4(CurrentCoords.x, CurrentCoords.y, CurrentCoords.z, heading)
                        utils.notify("location successfully created " .. #vc, "success", 8000)
                    else
                        utils.notify("cannot add spawn points outside the zone", "error", 8000)
                    end
                end
            end
            
            Wait(1)
        end

        results:resolve(#vc > 0 and vc or false)
        lib.hideTextUI()
    end)

    return results
end

return spawnPoint