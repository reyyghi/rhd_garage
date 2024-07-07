local Zones = {}

local creatorActive = false
local controlsActive = false
local xCoord, yCoord, zCoord, heading, height, width, length
local points = {}

local displayMode = 1
local minCheck = 0.025
local alignMovementWithCamera = true

local freecam = exports['fivem-freecam']

local function updateText()
	local text = {
        locale("createzone.1"),
        locale("createzone.2", xCoord),
        locale("createzone.3", yCoord),
        locale("createzone.4", zCoord),
        locale("createzone.5", height),
        locale("createzone.6"),
        locale("createzone.7"),
        locale("createzone.8"),
        locale("createzone.9"),
	}
	utils.drawtext('show',table.concat(text))
end

---@param number number
local function round(number)
	return number >= 0 and math.floor(number + 0.5) or math.ceil(number - 0.5)
end

--- Close Zone Creator
---@param cancel? boolean
---@param data? {onCreated:function}
local function closeCreator(cancel, data)
    
    freecam:SetActive(false)

	if not cancel then
		points[#points + 1] = vec(xCoord, yCoord, zCoord)
        if data and data.onCreated then
            local zoneData ---@type OxZone
            zoneData.points = points
            zoneData.thickness = height
            data.onCreated(zoneData)
        end
	end

	creatorActive = false
	controlsActive = false
	utils.drawtext('hide')
end

---@param rec vector3[]
local function drawRectangle(rec)
    DrawPoly(rec[1].x, rec[1].y, rec[1].z, rec[2].x, rec[2].y, rec[2].z, rec[3].x, rec[3].y, rec[3].z, 240, 229, 5, 120)
    DrawPoly(rec[2].x, rec[2].y, rec[2].z, rec[1].x, rec[1].y, rec[1].z, rec[3].x, rec[3].y, rec[3].z, 240, 229, 5, 120)
    DrawPoly(rec[1].x, rec[1].y, rec[1].z, rec[4].x, rec[4].y, rec[4].z, rec[3].x, rec[3].y, rec[3].z, 240, 229, 5, 120)
    DrawPoly(rec[4].x, rec[4].y, rec[4].z, rec[1].x, rec[1].y, rec[1].z, rec[3].x, rec[3].y, rec[3].z, 240, 229, 5, 120)
end

local function drawLines()
	local thickness = vec(0, 0, height / 2)
    local activeA, activeB = vec(xCoord, yCoord, zCoord) + thickness, vec(xCoord, yCoord, zCoord) - thickness

    DrawLine(activeA.x, activeA.y, activeA.z, activeB.x, activeB.y, activeB.z, 255, 42, 24, 225)

	for i = 1, #points do
		points[i] = vec(points[i].x, points[i].y, zCoord)
		local a = points[i] + thickness
		local b = points[i] - thickness
		local c = (points[i + 1] and vec(points[i + 1].x, points[i + 1].y, zCoord) or points[1]) + thickness
		local d = (points[i + 1] and vec(points[i + 1].x, points[i + 1].y, zCoord) or points[1]) - thickness
		local e = points[i]
		local f = (points[i + 1] and vec(points[i + 1].x, points[i + 1].y, zCoord) or points[1])

        if i == #points then
            DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, 255, 42, 24, 225)
            DrawLine(activeA.x, activeA.y, activeA.z, c.x, c.y, c.z, 255, 42, 24, 225)
            DrawLine(activeB.x, activeB.y, activeB.z, d.x, d.y, d.z, 255, 42, 24, 225)
            DrawLine(a.x, a.y, a.z, activeA.x, activeA.y, activeA.z, 255, 42, 24, 225)
            DrawLine(b.x, b.y, b.z, activeB.x, activeB.y, activeB.z, 255, 42, 24, 225)
            DrawLine(xCoord, yCoord, zCoord, f.x, f.y, f.z, 255, 42, 24, 225)
            DrawLine(e.x, e.y, e.z, xCoord, yCoord, zCoord, 255, 42, 24, 225)
        else
            DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, 255, 42, 24, 225)
            DrawLine(a.x, a.y, a.z, c.x, c.y, c.z, 255, 42, 24, 225)
            DrawLine(b.x, b.y, b.z, d.x, d.y, d.z, 255, 42, 24, 225)
            DrawLine(e.x, e.y, e.z, f.x, f.y, f.z, 255, 42, 24, 225)
        end

        if i == #points then
            drawRectangle({a, b, activeB, activeA})
            drawRectangle({activeA, activeB, d, c})
        else
            drawRectangle({a, b, d, c})
        end
	end
end

---@param origin vector2
---@param point vector2
---@param theta number
local function getRelativePos(origin, point, theta)
    if theta == 0.0 then return point end
    local p = point - origin
    local pX, pY = p.x, p.y
    theta = math.rad(theta)
    local cosTheta = math.cos(theta)
    local sinTheta = math.sin(theta)
    local x = math.floor(((pX * cosTheta - pY * sinTheta) + origin.x) * 100 + 0.0) / 100
    local y = math.floor(((pX * sinTheta + pY * cosTheta) + origin.y) * 100 + 0.0) / 100
    return x, y
end

local controls = {
    ['INPUT_LOOK_LR'] = 1,
    ['INPUT_LOOK_UD'] = 2,
    ['INPUT_MP_TEXT_CHAT_ALL'] = 245
}

---@param data? {onCreated:function}
function Zones.startCreator( data )
	creatorActive = true
    controlsActive = true

    local lStep = 0.05
    local rStep = 0.05
	local coords = GetEntityCoords(cache.ped)

	xCoord = round(coords.x) + 0.0
	yCoord = round(coords.y) + 0.0
	zCoord = round(coords.z) + 0.0
	heading = 0.0
	height = 4.0
	width = 4.0
	length = 4.0
	points = {}

	updateText()

    while creatorActive do
        Wait(0)
        if displayMode == 3 or displayMode == 4 then
            if alignMovementWithCamera then
                local rightX, rightY = getRelativePos(vec2(xCoord, yCoord), vec2(xCoord + 2, yCoord), freecam:GetRotation(2).z)
                local forwardX, forwardY = getRelativePos(vec2(xCoord, yCoord), vec2(xCoord, yCoord + 2), freecam:GetRotation(2).z)

                DrawLine(xCoord, yCoord, zCoord, rightX, rightY or 0, zCoord, 0, 255, 0, 225)
                DrawLine(xCoord, yCoord, zCoord, forwardX, forwardY or 0, zCoord, 0, 255, 0, 225)
            end

            DrawLine(xCoord, yCoord, zCoord, xCoord + 2, yCoord, zCoord, 0, 0, 255, 225)
            DrawLine(xCoord, yCoord, zCoord, xCoord, yCoord + 2, zCoord, 0, 0, 255, 225)
            DrawLine(xCoord, yCoord, zCoord, xCoord, yCoord, zCoord + 2, 0, 0, 255, 225)
        end

        drawLines()
        freecam:SetActive(true)

        if controlsActive then
            DisableAllControlActions(0)
            EnableControlAction(0, controls['INPUT_LOOK_LR'], true)
            EnableControlAction(0, controls['INPUT_LOOK_UD'], true)
            EnableControlAction(0, controls['INPUT_MP_TEXT_CHAT_ALL'], true)

            local change = false

            if IsDisabledControlJustReleased(0, 17) then -- scroll up
                if IsDisabledControlPressed(0, 21) then -- shift held down
                    change = true
                    height += lStep
                elseif IsDisabledControlPressed(0, 36) then -- ctrl held down
                    change = true
                    width += lStep
                elseif IsDisabledControlPressed(0, 19) then -- alt held down
                    change = true
                    length += lStep
                else
                    lStep += 0.05
                    rStep += 0.05
                end
            elseif IsDisabledControlJustReleased(0, 16) then -- scroll down
                if IsDisabledControlPressed(0, 21) then -- shift held down
                    change = true

                    if height - lStep > lStep then
                        height -= lStep
                    elseif height - lStep > 0 then
                        height = lStep
                    end
                elseif IsDisabledControlPressed(0, 36) then -- ctrl held down
                    change = true

                    if width - lStep > lStep then
                        width -= lStep
                    elseif width - lStep > 0 then
                        width = lStep
                    end
                elseif IsDisabledControlPressed(0, 19) then -- alt held down
                    change = true

                    if length - lStep > lStep then
                        length -= lStep
                    elseif length - lStep > 0 then
                        length = lStep
                    end
                else
                    lStep -= 0.05 rStep -= 0.05
                    if lStep < 0.02 or rStep < 0.02 then
                        lStep = 0.02 rStep = 0.02
                    end
                end
            elseif IsDisabledControlPressed(0, 188) then --- arrow up
                change = true

                if alignMovementWithCamera then
                    local newX, newY = getRelativePos(vec2(xCoord, yCoord), vec2(xCoord, yCoord + lStep), freecam:GetRotation(2).z)

                    if math.abs(newX) < minCheck then
                        newX = 0.0
                    end

                    if math.abs(newY or 0) < minCheck then
                        newY = 0.0
                    end

                    xCoord = newX
                    yCoord = newY
                else
                    local newValue = yCoord + lStep

                    if math.abs(newValue) < minCheck then
                        newValue = 0.0
                    end

                    yCoord = newValue
                end
            elseif IsDisabledControlPressed(0, 187) then --- arrow down
                change = true

                if alignMovementWithCamera then
                    local newX, newY = getRelativePos(vec2(xCoord, yCoord), vec2(xCoord, yCoord - lStep), freecam:GetRotation(2).z)

                    if math.abs(newX) < minCheck then
                        newX = 0.0
                    end

                    if math.abs(newY or 0) < minCheck then
                        newY = 0.0
                    end

                    xCoord = newX
                    yCoord = newY
                else
                    local newValue = yCoord - lStep

                    if math.abs(newValue) < minCheck then
                        newValue = 0.0
                    end

                    yCoord = newValue
                end
            elseif IsDisabledControlPressed(0, 190) then --- arrow right
                change = true

                if alignMovementWithCamera then
                    local newX, newY = getRelativePos(vec2(xCoord, yCoord), vec2(xCoord + lStep, yCoord), freecam:GetRotation(2).z)

                    if math.abs(newX) < minCheck then
                        newX = 0.0
                    end

                    if math.abs(newY or 0) < minCheck then
                        newY = 0.0
                    end

                    xCoord = newX
                    yCoord = newY
                else
                    local newValue = xCoord + lStep

                    if math.abs(newValue) < minCheck then
                        newValue = 0.0
                    end

                    xCoord = newValue
                end
            elseif IsDisabledControlPressed(0, 189) then --- arrow left
                change = true

                if alignMovementWithCamera then
                    local newX, newY = getRelativePos(vec2(xCoord, yCoord), vec2(xCoord - lStep, yCoord), freecam:GetRotation(2).z)

                    if math.abs(newX) < minCheck then
                        newX = 0.0
                    end

                    if math.abs(newY or 0) < minCheck then
                        newY = 0.0
                    end

                    xCoord = newX
                    yCoord = newY
                else
                    local newValue = xCoord - lStep

                    if math.abs(newValue) < minCheck then
                        newValue = 0.0
                    end

                    xCoord = newValue
                end
            elseif IsDisabledControlJustReleased(0, 45) then -- r
                change = true
                local newValue = zCoord + lStep

                if math.abs(newValue) < minCheck then
                    newValue = 0.0
                end

                zCoord = newValue
            elseif IsDisabledControlJustReleased(0, 23) then -- f
                change = true
                local newValue = zCoord - lStep

                if math.abs(newValue) < minCheck then
                    newValue = 0.0
                end

                zCoord = newValue
            elseif IsDisabledControlJustReleased(0, 38) then -- e
                change = true
                heading -= rStep

                if heading < 0 then
                    heading += 360
                end
            elseif IsDisabledControlJustReleased(0, 44) then -- q
                change = true
                heading += rStep

                if heading >= 360 then
                    heading -= 360
                end
            elseif IsDisabledControlJustReleased(0, 22) then -- space
                change = true

                points[#points + 1] = vec2(xCoord, yCoord)

                local newC = nil

                for i=1, #points do
                    newC = points[i]
                end

                coords = newC
                xCoord = round(coords.x)
                yCoord = round(coords.y)
            elseif IsDisabledControlJustReleased(0, 201) then -- enter
                closeCreator(false, data)
            elseif IsDisabledControlJustReleased(0, 194) then -- backspace
                change = true

                if #points > 0 then
                    xCoord = points[#points].x
                    yCoord = points[#points].y

                    points[#points] = nil
                end
            elseif IsDisabledControlJustReleased(0, 200) then -- esc
                SetPauseMenuActive(false)
                closeCreator(true)
            end

            if change then
                updateText()
            end
        end
    end
end

return Zones
