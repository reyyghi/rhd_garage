if GetResourceState('es_extended') == "missing" then return end

local ESX = exports["es_extended"]:getSharedObject()

PLAYERs = {}
Framework = {}

local config = require 'config.client'

---@class server : OxClass
local server = lib.class('server')

function server:constructor(xPlayer)
    
    self.source = xPlayer.source
    self.identifier = xPlayer.identifier
    self.name = xPlayer.name

    self.getMoney = function (type)
        type = type == 'cash' and 'money' or type
        local money = xPlayer.getAccount(type).money
        return money or 0
    end

    self.removeMoney = function (type, count)
        type = type == 'cash' and 'money' or type
        if self.getMoney(type) >= count then
            xPlayer.removeAccountMoney(type, count)
            return true
        end
        return false
    end

    return self
end

function Framework.getPlayerByIdentifier(identifier)
    for _, xPlayer in pairs(PLAYERs) do
        if xPlayer.identifier == identifier then
            return xPlayer
        end
    end
    return false
end

AddEventHandler("esx:playerLoaded", function(_, xPlayer)
    if PLAYERs[xPlayer.source] then return end

    PLAYERs[xPlayer.source] = server:new(xPlayer)
    xPlayer.triggerEvent('rhd_garage:loadPlayer', xPlayer)
    PrepareGarage(xPlayer.source)
end)

AddEventHandler('playerDropped', function (reason)
    local src = source
    if PLAYERs[src] then
        PLAYERs[src] = nil
    end
end)

if config.InDevelopment then
    lib.addCommand('reloadgarage', {
        help = 'Use this command if you have finished restarting this resource.',
        restricted = 'group.admin'
    }, function(source, args, raw)
        local xPlayer = ESX.GetPlayerFromId(source)

        PLAYERs[xPlayer.source] = server:new(xPlayer)
        xPlayer.triggerEvent('rhd_garage:loadPlayer', xPlayer)
        PrepareGarage(xPlayer.source)
    end)
end