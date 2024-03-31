if GetResourceState('qb-core') == "missing" then return end

local QBCore = exports['qb-core']:GetCoreObject()
local Utils = require "modules.utils"
local isServer = IsDuplicityVersion()

fw = {
    player = {
        name = "Unkown Players",
        money = {
            cash = 0,
            bank = 0
        },
        job = {
            name = "none",
            grade = 0
        },
        gang = {
            name = "none",
            grade = 0
        }
    }
}

--- Get Money
---@param type string
---@return integer
function fw.gm(type)
    return fw.player.money?[type] or 0    
end

---@return string
function fw.gn()
    return fw.player.name
end

--- Get Vehicle Name
---@param model string
function fw.gvn(model)
    local vd = QBCore.Shared.Vehicles[model]
    return vd?.name or GetDisplayNameFromVehicleModel(model)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local charinfo = PlayerData.charinfo

    local Job = PlayerData.job
    local Gang = PlayerData.gang
    local Money = PlayerData.money

    fw.player.name = charinfo.firstname .. " " .. charinfo.lastname
    fw.player.money = Money

    fw.player.job = {
        name = Job.name,
        grade = Job.grade
    }
    fw.player.gang = {
        name = Gang.name,
        grade = Gang.grade
    }
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(PlayerData)
    local Job = PlayerData.job
    local Gang = PlayerData.gang
    local Money = PlayerData.money
    local Charinfo = PlayerData.charinfo

    fw.player.name = Charinfo.firstname .. " " .. Charinfo.lastname
    fw.player.money = Money

    fw.player.job = {
        name = Job.name,
        grade = Job.grade
    }
    fw.player.gang = {
        name = Gang.name,
        grade = Gang.grade
    }
end)

if isServer then
    local xPlayer = {}

    --- Get Player
    ---@param src number
    ---@return boolean
    function fw.gp(src)
        if not xPlayer then return false end
        return xPlayer[tostring(src)] or false
    end

    --- Get Identifier
    ---@param src number
    ---@return boolean
    function fw.gi(src)
        return xPlayer[tostring[src]] or false
    end

    --- Player Remove Money
    ---@param src number playerid
    ---@param type string cash | bank
    ---@param amount number amount of money
    ---@return boolean
    function fw.rm(src, type, amount)
        local p = QBCore.Functions.GetPlayer(src)
        if not p then return false end
        return p.Functions.RemoveMoney(type, amount, '')
    end

    --- Get Player Name
    ---@param src number
    ---@return string
    function fw.gn(src)
        local idstr = tostring(src)
        local charinfo = xPlayer[idstr]?.charinfo or {}
        return next(charinfo) and ("%s %s"):format(charinfo.firstname, charinfo.lastname) or "Unkown Players"
    end

    --- Get Shared Vehicle
    ---@param model string
    ---@return table
    function fw.gsv(model)
        return QBCore.Shared.Vehicles[model] or {}
    end

    RegisterNetEvent('QBCore:Player:SetPlayerData', function(PlayerData)
        local src = PlayerData.source
        local idstr = tostring(src)
        xPlayer[idstr] = PlayerData
    end)

    RegisterNetEvent('QBCore:Server:PlayerLoaded', function(player)
        local src = player.PlayerData.source
        local idstr = tostring(src)
        xPlayer[idstr] = player.PlayerData
        Utils.print("success", ("Register new cache for %s"):format(GetPlayerName(src)))
    end)

    AddEventHandler("playerDropped", function ()
        local src = source
        local idstr = tostring(src)
        xPlayer[idstr] = nil
        Utils.print("success", ("Remove cache from %s"):format(GetPlayerName(src)))
    end)
end