local BLIP_DEFAULT = {
    default = {
        sprite = 357,
        colour = 3
    },
    impound = {
        sprite = 68,
        colour = 3
    }
}

local function groupsInput()
    local input = lib.inputDialog('Garage Groups', {
        { type = 'input', label = 'Name', placeholder = 'Enter job/gang name', required = true, description = 'The name of the job or gang you want to add.' },
        { type = 'number', label = 'Rank', required = true, description = 'Enter the rank for this job/gang. The rank determines the hierarchy or priority level.' },
    })

    return input and {
        name = input[1],
        rank = input[2]
    }
end

local function blipInput(default)
    local input = lib.inputDialog('Garage Blip', {
        { type = 'number', label = 'Sprite', default = default.sprite, description = 'Enter the sprite ID for the blip. This determines the icon that will appear on the map.', required = true },
        { type = 'number', label = 'Colour', default = default.colour, description = 'Enter the color ID for the blip. This sets the color of the icon on the map.', required = true }
    }, {
        allowCancel = true
    })

    return input and {
        sprite = input[1],
        colour = input[2],
    }
end

local function createGaragePoints()
    local input = lib.inputDialog('Garage Creator (Points)', {
        { type = 'input', label = 'Label', description = 'Enter a label for the garage point. This will be used to identify the point.', required = true },
        { type = 'checkbox', label = 'Blip', description = 'Enable a blip on the map to make this garage point visible to players.' },
        { type = 'checkbox', label = 'Groups', description = 'Select if this garage point should be accessible to specific jobs or gangs.' },
    
        { type = 'select', label = 'Type', description = 'Choose the type of garage. This determines how the garage behaves and interacts with players.', options = {
            { label = 'Depot', value = 'impound' },
            { label = 'Default', value = 'default' },
            { label = 'Shared', value = 'shared' }
        }},
    
        { type = 'multi-select', label = 'Vehicle Class', description = 'Select the types of vehicles that can be stored in this garage.', options = {
            { label = 'Car', value = 'car' },
            { label = 'Motorcycle', value = 'motorcycle' },
            { label = 'Bicycle', value = 'bicycle' },
            { label = 'Truck', value = 'truck' },
            { label = 'Helicopter', value = 'helicopter' },
            { label = 'Boat', value = 'boat' },
            { label = 'All', value = 'all' }
        }}
    })

    if not input then return end

    local label = input[1]
    local garageType = input[4]
    local garageClass = input[5]
    
    local blip = input[2] and blipInput(BLIP_DEFAULT[garageType])
    local groups = input[3] and groupsInput()

    local data = {
        type = garageType,
        blip = blip,
        label = label,
        class = garageClass,
        groups = groups and {
            [groups.name] = groups.rank
        },
        points = exports.garage_creator:createPoint()
    }

    TriggerServerEvent('rhd_garage:server:registerGarage', data)
end

local function creatorMenu()
    local input = lib.inputDialog('RHD GARAGE', {
        { type = 'select', label = 'Type', description = 'Use zones or points', options = {
            {label = 'Zones', value = 'zones'},
            {label = 'Points', value = 'points'}
        }},
    })

    if not input then
        return
    end

    if input[1] == 'points' then
        createGaragePoints()
    end
end

RegisterNetEvent('rhd_garage:client:create', creatorMenu)