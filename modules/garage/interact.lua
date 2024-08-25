---@class interact: OxClass
local interact = lib.class('interact')

---@class targetOptions
---@field label string
---@field icon string
---@field distance number
---@field groups? string|string[]|table<string, number>
---@field onSelect fun()

---@class targetData
---@field model string
---@field coords vector4
---@field label string
---@field icon string
---@field distance number
---@field onSelect fun()

local interactUsed = Config.interact.target

---@param targetData targetData
local function createTargetPed(targetData)
    local td = targetData

    local id = td.label
    lib.requestModel(td.model, 1500)
    local entity = CreatePed(0, td.model, td.coords.x, td.coords.y, td.coords.z - 1, td.coords.w, false, false)
    FreezeEntityPosition(entity, true)
    SetEntityInvincible(entity, true)
    SetBlockingOfNonTemporaryEvents(entity, true)

    if interactUsed == 'ox' then
        id = td.label:gsub("%s+", "")
        exports.ox_target:addLocalEntity(entity, {
            {
                name = id,
                label = td.label,
                icon = td.icon,
                distance = td.distance,
                onSelect = td.onSelect
            }
        })
    elseif interactUsed == 'qb' then
        exports['qb-target']:AddTargetEntity(entity, {
            options = {
                {
                    icon = td.icon,
                    label = td.label,
                    action = td.onSelect,
                }
            },
            distance = td.distance,
        })
    elseif interactUsed == 'interact' then
        id = exports.interact:AddLocalEntityInteraction({
            entity = entity,
            distance = td.distance * 2,
            interactDst = td.distance,
            ignoreLos = true,
            options = {
                {
                    label = td.label,
                    action = td.onSelect
                },
            }
        })
    end

    return entity, id
end

---@param interactType string
---@param interactData targetData
function interact:constructor(interactType, interactData)
    if interactType == 'targetped' then
        self.entity, self.id = createTargetPed(interactData)
    end
    return self
end

function interact:remove()
    if self.entity then

        if interactUsed == 'ox' then
            exports.ox_target:removeLocalEntity(self.entity, self.id)
        elseif interactUsed == 'qb' then
            exports['qb-target']:RemoveTargetEntity(self.entity, self.id)
        elseif interactUsed == 'interact' then
            exports.interact:RemoveLocalEntityInteraction(self.entity, self.id)
        end

        if DoesEntityExist(self.entity) then
            DeleteEntity(self.entity)
        end

        self.entity = nil self.id = nil
    end
end

return interact