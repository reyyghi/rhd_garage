if GetResourceState('qbx_core') == "missing" then return end

---@class client : OxClass
local client = lib.class('client')

function client:constructor(xPlayer)
    local playerData = xPlayer.PlayerData
    local playerJob = playerData.job
    local playerGang = playerData.gang

    self.groups = {}
    self.money = playerData.money
    self.loaded = true

    self.groups = {
        job = {
            name = playerJob.name,
            label = playerJob.label,
            rank = playerJob.grade.level,
            rankLabel = playerJob.grade.name
        },
        gang = {
            name = playerGang.name,
            label = playerGang.label,
            rank = playerGang.grade.level,
            rankLabel = playerGang.grade.name
        }
    }

    self.name = ('%s %s'):format(playerData.charinfo.firstname, playerData.charinfo.lastname)

    return self
end

function client:getMoney(type)
    assert(self.money[type], 'The specified money type "' .. type .. '" does not exist')
    return self.money[type]
end

function client:checkGroups(groups)
    local _type = type(groups)

    for _, data in pairs(self.groups) do
        if _type == "string" then
            return data.name == groups
        elseif _type == "table" then
            local _tabletype = table.type(groups)

            if _tabletype == 'hash' then
                return groups[data.name] and data.rank >= groups[data.name]
            elseif _tabletype == 'array' then
                return Array.find(groups, function (name)
                    if data.name == name then
                        return true
                    end
                end)
            end
        end
    end
end

function client:updateMoney(account)
    self.money[account.name == 'money' and 'cash' or account.name] = account.money
end

function client:updateJob(newjob)
    self.groups.job = {
        name = newjob.name,
        label = newjob.label,
        rank = newjob.grade.level,
        rankLabel = newjob.grade.name
    }
end

function client:updateGang(newgang)
    self.groups.gang = {
        name = newgang.name,
        label = newgang.label,
        rank = newgang.grade.level,
        rankLabel = newgang.grade.name
    }
end

function client:getMyName()
    return LocalPlayer.state.name
end

PLAYER = {}

RegisterNetEvent('QBCore:Client:OnMoneyChange', function(moneytype, amount)
    PLAYER:updateMoney({name = moneytype, money = amount})
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PLAYER:updateJob(job)
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
    PLAYER:updateGang(gang)
end)


RegisterNetEvent('rhd_garage:loadPlayer', function(xPlayer)
    if GetInvokingResource() then return end

    PLAYER = client:new(xPlayer)
end)