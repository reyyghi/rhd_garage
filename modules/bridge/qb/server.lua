if GetResourceState('qb-core') == "missing" then return end

local QBCore = exports['qb-core']:GetCoreObject()

local config = require 'config.client'

PLAYERs = {}
Framework = {}

---@class server : OxClass
local server = lib.class('server')

function server:constructor(xPlayer)
    local playerData = xPlayer.PlayerData
    self.source = playerData.source
    self.identifier = playerData.citizenid
    
    self.name = ('%s %s'):format(playerData.charinfo.firstname, playerData.charinfo.lastname)
    self.removeMoney = xPlayer.Functions.RemoveMoney

    self.getMoney = function (type)
        return xPlayer.Functions.GetMoney(type) or 0
    end

    self.removeMoney = function (type, count)
        return xPlayer.Functions.RemoveMoney(type, count)
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

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if PLAYERs[xPlayer.PlayerData.source] then return end

    PLAYERs[xPlayer.PlayerData.source] = server:new(xPlayer)
    xPlayer.triggerEvent('rhd_garage:reloadgarage', xPlayer)
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
        local xPlayer = QBCore.Functions.GetPlayer(source)
        if PLAYERs[xPlayer.PlayerData.source] then return end
        PLAYERs[xPlayer.PlayerData.source] = server:new(xPlayer)
        xPlayer.triggerEvent('rhd_garage:reloadgarage', xPlayer)
    end)
end