if GetResourceState('es_extended') == "missing" then return end

---@class client : OxClass
local client = lib.class('client')

function client:constructor(xPlayer)
    local playerJob = xPlayer.job

    self.groups = {}
    self.money = {}
    self.loaded = true

    self.groups[playerJob.name] = {
        label = playerJob.label,
        rank = playerJob.grade,
        rankLabel = playerJob.grade_label
    }
    
    self.name = xPlayer.name

    lib.array.forEach(xPlayer.accounts, function (account)
        self.money[account.name == 'money' and 'cash' or account.name] = account.money
    end)

    return self
end

function client:getMoney(type)
    assert(self.money[type], 'The specified money type "' .. type .. '" does not exist')
    return self.money[type]
end

function client:checkGroups(groups)
    local isTable = lib.array.isArray(groups)
    
    if isTable then
        lib.array.forEach(groups, function (name)
            if self.groups[name] then
                return true
            end
        end)
        for name, grade in pairs(groups) do
            if self.groups[name] then
                return self.groups[name].rank >= grade
            end
        end
        return false
    end

    return self.groups[groups]
end

function client:updateMoney(account)
    self.money[account.name == 'money' and 'cash' or account.name] = account.money
end

function client:updateJob(newjob)
    self.groups[newjob.name] = {
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

RegisterNetEvent('rhd_garage:reloadgarage', function(xPlayer)
    if GetInvokingResource() then return end

    PLAYER = client:new(xPlayer)
end)