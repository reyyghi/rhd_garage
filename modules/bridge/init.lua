local isStarted = function (resource)
    return GetResourceState(resource) == 'started'
end

local fileType = IsDuplicityVersion() and 'server' or 'client'
local framework = isStarted('es_extended') and 'esx' or 'qb'

lib.load(('modules.bridge.%s.%s'):format(framework, fileType))
