---@class client : OxClass
local client = lib.class('client')

function client:constructor(xPlayer)
    local playerJob = xPlayer.job

    self.groups = {}
    self.money = {}
    self.loaded = true

    self.groups = {
        job = {
            name = playerJob.name,
            label = playerJob.label,
            rank = playerJob.grade,
            rankLabel = playerJob.grade_label
        }
    }
    
    self.name = xPlayer.name

    Array.forEach(xPlayer.accounts, function (account)
        self.money[account.name == 'money' and 'cash' or account.name] = account.money
    end)

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
        rank = newjob.grade,
        rankLabel = newjob.grade_label
    }
end

function client:getMyName()
    return LocalPlayer.state.name
end

PLAYER = {}

RegisterNetEvent("esx:setAccountMoney")
AddEventHandler("esx:setAccountMoney", function(account)
    if type(account) ~= "table" then return end
    
    PLAYER:updateMoney(account)
end)

RegisterNetEvent("esx:setJob", function(newJob)
    if type(newJob) ~= "table" then return end

    PLAYER:updateJob(newJob)
end)

RegisterNetEvent('rhd_garage:loadPlayer', function(xPlayer)
    if GetInvokingResource() then return end

    PLAYER = client:new(xPlayer)
end)