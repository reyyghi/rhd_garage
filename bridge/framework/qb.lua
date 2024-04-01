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
    },
    qb = true
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
    ---@return string | boolean
    function fw.gi(src)
        return xPlayer[tostring(src)]?.citizenid or false
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

    --- Get Vehicle Mods & Deformation By Plate
    ---@param plate any
    function fw.gmdbp(plate)
        local results = MySQL.single.await("SELECT mods, deformation FROM player_vehicles WHERE plate = ? OR fakeplate = ?", {plate, plate})
        if not results then return {prop = {}, deformation = {},} end
        return {prop = json.decode(results.mods), deformation = json.decode(results.deformation)}
    end

    --- Update Vehicle State
    ---@param plate string
    ---@param state number
    ---@param garage string
    ---@return boolean
    function fw.uvs(plate, state, garage)
        local Update = MySQL.update.await("UPDATE player_vehicles SET state = ?, garage = ? WHERE plate = ? OR fakeplate = ?", {state, garage, plate, plate})
        return Update > 0
    end

    ---- Get Vehicle Owner By Plate
    ---@param src number
    ---@param plate string
    ---@param filter {onlyOwner: boolean}
    ---@param pleaseUpdate {mods: table, deformation: table}
    ---@return table | boolean
    function fw.gvobp(src, plate, filter, pleaseUpdate)
        local identifier = fw.gi(src)
        if not identifier then return false end

        local format = [[
            SELECT
                pv.vehicle,
                p.charinfo
            FROM player_vehicles pv LEFT JOIN players p ON pv.citizenid = p.citizenid
                WHERE
                    pv.plate = ? OR pv.fakeplate = ?
        ]]
        local value = {plate, plate}

        if filter and filter.onlyOwner then
            format = [[
                SELECT
                    pv.vehicle,
                    p.charinfo
                FROM player_vehicles pv LEFT JOIN players p ON pv.citizenid = p.citizenid
                    WHERE
                        pv.plate = ? OR pv.fakeplate = ? AND pv.citizenid = ?
            ]]
            value = {plate, plate, identifier}
        end

        local results = MySQL.single.await(format, value)
        if not results then return false end
        local charinfo = json.decode(results.charinfo)
        local ownername = ("%s %s"):format(charinfo.firstname, charinfo.lastname)

        if pleaseUpdate then
            MySQL.update([[
                UPDATE
                    player_vehicles
                        SET
                mods = ?, deformation = ? WHERE plate = ?
            ]], {
                json.encode(pleaseUpdate.mods),
                json.encode(pleaseUpdate.deformation)
            })
        end

        return {
            vehmodel = results.vehicle,
            ownername = ownername
        }
    end

    --- Get Player Vehicles By Garage
    ---@param src string
    ---@param garage string
    ---@param filter {impound: boolean, shared: boolean}
    function fw.gpvbg(src, garage, filter)
        local Identifier = fw.gi(src)
        if not Identifier then return {} end
        local format = [[
            SELECT vehicle, mods, state, depotprice, plate, fakeplate, deformation FROM player_vehicles WHERE citizenid = ? AND garage = ? AND state = ?
        ]]

        local value = {Identifier, garage, 1}
        if filter then
            if not filter.impound then
                if filter.shared then
                    format = [[
                        SELECT
                            pv.vehicle, 
                            pv.mods,
                            pv.state,
                            pv.depotprice,
                            pv.plate,
                            pv.fakeplate,
                            pv.deformation,
                            p.charinfo
                        FROM player_vehicles pv LEFT JOIN players p ON p.citizenid = pv.citizenid WHERE pv.garage = ? AND pv.state = ?
                    ]]
                    value = {garage, 1}
                end
            else
                format = [[
                    SELECT vehicle, mods, state, depotprice, plate, fakeplate, deformation FROM player_vehicles WHERE citizenid = ? AND state = 0
                ]]
                value = {Identifier, 0}
            end
        end

        local vehicles = {}
        local results = MySQL.query.await(format, value)

        if results and #results > 0 then
            for i=1, #results do
                local data = results[i]
                local mods = json.decode(data.mods)
                local deformation = json.decode(data.deformation)
                local state = data.state
                local model = data.vehicle
                local plate = data.plate
                local depotprice = data.depotprice
                local fakeplate = data.fakeplate
                
                vehicles[#vehicles+1] = {
                    vehicle = mods,
                    state = state,
                    model = model,
                    plate = plate,
                    fakeplate = fakeplate,
                    depotprice = depotprice,
                    deformation = deformation
                }

                if filter.shared then
                    local charinfo = json.decode(data.charinfo)
                    local ownername = ("%s %s"):format(charinfo.firstname, charinfo.lastname)
                    vehicles[#vehicles].owner = ownername
                end
            end
        end
        return vehicles
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

    RegisterCommand("reloadcache", function (src)
        local p = QBCore.Functions.GetPlayer(src)
        if not p then return false end
        local idstr = tostring(src)
        xPlayer[idstr] = p.PlayerData
    end, false)
end