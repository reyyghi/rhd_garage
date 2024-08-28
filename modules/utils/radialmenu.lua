---@class RadialMenu: OxClass
local RadialMenu = lib.class('RadialMenu')

local config = require 'config.client'
local radialUsed = config.radialMenu

function RadialMenu:constructor(radialData)
    local context1 = radialData[1]
    local context2 = radialData[2]

    if radialUsed == 'ox' then
        lib.addRadialItem({
            {
                id = context1.id,
                label = context1.label,
                icon = context1.icon,
                onSelect = context1.onSelect
            },
            {
                id = context2.id,
                label = context2.label,
                icon = context2.icon,
                onSelect = context2.onSelect
            }
        })
    elseif radialUsed == 'qb' then
        local id1 = exports['qb-radialmenu']:AddOption({
            id = context1.id,
            title = context1.label,
            icon =  context1.icon == "parking" and "square-parking" or context1.icon,
            action = context1.onSelect,
            shouldClose = true
        })
        local id2 = exports['qb-radialmenu']:AddOption({
            id = context2.id,
            title = context2.label,
            icon =  context2.icon == "parking" and "square-parking" or context2.icon,
            action = context2.onSelect,
            shouldClose = true
        })
        context1.id, context2.id = id1, id2
    end

    self.id = {context1.id, context2.id}
end

function RadialMenu:remove()
    if not lib.array.isArray(self.id) then
        return
    end
    lib.array.forEach(self.id, function (id)
        if radialUsed == 'ox' then
            lib.removeRadialItem(id)
        elseif radialUsed == 'qb' then
            exports['qb-radialmenu']:RemoveOption(id)
        end
    end)
end

return RadialMenu