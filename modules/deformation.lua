local Deformation = {}

---@param value number
---@param numDecimals number
local function Round (value, numDecimals)
	return math.floor(value * 10^numDecimals) / 10^numDecimals
end

---@param vehicle integer
local function GetVehicleOffsetsForDeformation (vehicle)
	local min, max = GetModelDimensions(GetEntityModel(vehicle))
	local X = Round((max.x - min.x) * 0.5, 2)
	local Y = Round((max.y - min.y) * 0.5, 2)
	local Z = Round((max.z - min.z) * 0.5, 2)
	local halfY = Round(Y * 0.5, 2)

	return {
		vector3(-X, Y,  0.0),
		vector3(-X, Y,  Z),

		vector3(0.0, Y,  0.0),
		vector3(0.0, Y,  Z),

		vector3(X, Y,  0.0),
		vector3(X, Y,  Z),


		vector3(-X, halfY,  0.0),
		vector3(-X, halfY,  Z),

		vector3(0.0, halfY,  0.0),
		vector3(0.0, halfY,  Z),

		vector3(X, halfY,  0.0),
		vector3(X, halfY,  Z),


		vector3(-X, 0.0,  0.0),
		vector3(-X, 0.0,  Z),

		vector3(0.0, 0.0,  0.0),
		vector3(0.0, 0.0,  Z),

		vector3(X, 0.0,  0.0),
		vector3(X, 0.0,  Z),


		vector3(-X, -halfY,  0.0),
		vector3(-X, -halfY,  Z),

		vector3(0.0, -halfY,  0.0),
		vector3(0.0, -halfY,  Z),

		vector3(X, -halfY,  0.0),
		vector3(X, -halfY,  Z),


		vector3(-X, -Y,  0.0),
		vector3(-X, -Y,  Z),

		vector3(0.0, -Y,  0.0),
		vector3(0.0, -Y,  Z),

		vector3(X, -Y,  0.0),
		vector3(X, -Y,  Z),
	}
end

---@param vehicle integer
---@param deformation table[]
Deformation.set = function (vehicle, deformation)
    local fDeformationDamageMult = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fDeformationDamageMult")
    local damageMult = 20.0
    if (fDeformationDamageMult <= 0.55) then
        damageMult = 1000.0
    elseif (fDeformationDamageMult <= 0.65) then
        damageMult = 400.0
    elseif (fDeformationDamageMult <= 0.75) then
        damageMult = 200.0
    end

    if deformation and next(deformation) then
        for k, v in pairs(deformation) do
			local x, y, z, d = v.offset.x, v.offset.y, v.offset.z, (v.damage * damageMult)
			if d > 14.0 then
				d  = 14.5
			end
            SetVehicleDamage(vehicle, x, y, z, d, 1000.0, true)
        end
    end
 
end

---@param vehicle integer
---@return table
Deformation.get = function ( vehicle )
    local data = {}
	local offsets = GetVehicleOffsetsForDeformation(vehicle)
    local dmg = 0

    for k, v in ipairs(offsets) do
		dmg = math.floor(#(GetVehicleDeformationAtPos(vehicle, v.x, v.y, v.z)) * 1000.0) / 1000.0
		data[#data+1] = { offset = v, damage = dmg }
	end

    return data
end

return Deformation