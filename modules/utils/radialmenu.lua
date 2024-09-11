---@class RadialMenu: OxClass
local RadialMenu = lib.class('RadialMenu')

local config = require 'config.client'
local radialUsed = config.radialMenu

function RadialMenu:constructor(radialData)
    local context1 = radialData[1] or {}
    local context2 = radialData[2] or {}

    if radialUsed == 'ox' then
        local items = {}

        if context1.id then
            items[1] = {
                id = context1.id,
                label = context1.label,
                icon = context1.icon,
                onSelect = context1.onSelect
            }
        end
        if context2.id then
            items[2] = {
                id = context1.id,
                label = context1.label,
                icon = context1.icon,
                onSelect = context1.onSelect
            }
        end

        if items[1] then
            lib.addRadialItem(items)
        end
    elseif radialUsed == 'qb' then
        local id1, id2
        if context1.id then
            id1 = exports['qb-radialmenu']:AddOption({
                id = context1.id,
                title = context1.label,
                icon =  context1.icon == "parking" and "square-parking" or context1.icon,
                action = context1.onSelect,
                shouldClose = true
            })
        end
        if context2.id then
            id2 = exports['qb-radialmenu']:AddOption({
                id = context2.id,
                title = context2.label,
                icon =  context2.icon == "parking" and "square-parking" or context2.icon,
                action = context2.onSelect,
                shouldClose = true
            })
        end
        context1.id, context2.id = id1, id2
    elseif radialUsed == 'rhd' then
        if context1.id then
            exports.rhd_radialmenu:AddItem({
                id = context1.id,
                title = context1.label,
                icon = context1.icon,
                action = context1.onSelect
            })
        end
        if context2.id then
            exports.rhd_radialmenu:AddItem({
                id = context2.id,
                title = context2.label,
                icon = context2.icon,
                action = context2.onSelect
            })
        end
    end

    self.id = {context1.id, context2.id}
end

function RadialMenu:remove()
    if not Array.isArray(self.id) then
        return
    end
    Array.forEach(self.id, function (id)
        if radialUsed == 'ox' then
            lib.removeRadialItem(id)
        elseif radialUsed == 'qb' then
            exports['qb-radialmenu']:RemoveOption(id)
        elseif radialUsed == 'rhd' then
            exports.rhd_radialmenu:RemoveItem(id)
        end
    end)
end

return RadialMenu