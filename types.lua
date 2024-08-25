
-- ---@meta

-- ---@class OxZone
-- ---@field points vector3[] --- Array of points defining the zone boundaries
-- ---@field thickness number --- Thickness of the zone boundaries

-- ---@class BlipData
-- ---@field type integer --- Sprite ID for the map blip
-- ---@field color integer --- Color ID for the map blip
-- ---@field label string --- Label for the map blip

-- ---@class GarageData
-- ---@field type? string[] --- Types of vehicles allowed in the garage
-- ---@field blip? BlipData --- Data for the map blip associated with the garage
-- ---@field impound? boolean --- Whether the garage is used for impounding vehicles
-- ---@field shared? boolean --- Whether the garage is shared
-- ---@field interaction? string|{coords: vector4, model:string|integer} --- Interaction details for the garage
-- ---@field job? table<string, number> --- Jobs allowed to use the garage
-- ---@field gang? table<string, number> --- Gangs allowed to use the garage
-- ---@field spawnPoint? vector4[] --- Spawn points for vehicles in the garage
-- ---@field spawnPointVehicle? string[] --- Types of vehicles that can spawn in the garage
-- ---@field zones? OxZone --- Zones defining the area of the garage

-- ---@class CustomName
-- ---@field name? string --- Custom name for a vehicle

-- ---@class RadialArguments
-- ---@field garage string --- The name of the garage associated with the radial menu item
-- ---@field type string[] --- Array of vehicle types relevant to the radial menu item
-- ---@field impound? boolean --- Optional; Indicates whether the garage is used for impounding vehicles
-- ---@field shared? boolean --- Optional; Indicates whether the garage is shared
-- ---@field spawnpoint vector4[] --- Array of spawn points for the garage

-- ---@class RadialData
-- ---@field id string --- ID for the radial menu item
-- ---@field label string --- Label for the radial menu item
-- ---@field icon string --- Icon for the radial menu item
-- ---@field event? string --- Event triggered by the radial menu item
-- ---@field args RadialArguments --- Arguments for the event

-- ---@class TargetOptions
-- ---@field label string
-- ---@field icon string
-- ---@field distance number
-- ---@field groups? string|string[]|table<string, number>
-- ---@field action fun()

-- ---@class ContextOptions
-- ---@field id string
-- ---@field title string
-- ---@field options ContextMenuItem[]

-- ---@class GarageVehicleData
-- ---@field garage? string --- Name of the garage
-- ---@field type? string[] --- Types of vehicles in the garage
-- ---@field impound? boolean --- Whether the garage is used for impounding vehicles or insurance
-- ---@field shared? boolean --- Whether the garage is shared
-- ---@field spawnpoint? vector3[] --- Spawn points for vehicles in the garage
-- ---@field targetped? boolean --- Whether the garage uses a ped for interaction
-- ---@field depotprice? number --- Price for depot services
-- ---@field props? table --- Vehicle properties
-- ---@field deformation? table --- Vehicle deformation properties
-- ---@field body? number --- Vehicle body health
-- ---@field engine? number --- Vehicle engine health
-- ---@field fuel? number --- Vehicle fuel level
-- ---@field plate? string --- Vehicle plate number
-- ---@field vehName? string --- Vehicle name (1st version)
-- ---@field vehicle_name? string --- Vehicle name (2nd version)
-- ---@field model? string|integer --- Vehicle model
-- ---@field coords? vector3|vector4 --- Vehicle spawn coordinates
-- ---@field ignoreDist? boolean

-- utils = {}
-- utils.string = {}

-- local server = IsDuplicityVersion()

-- ---@param string string --- String to trim
-- ---@return string? --- Returns trimmed string or nil if input is nil
-- function utils.string.trim(string) end

-- ---@param string string --- String to check
-- ---@return string? --- Returns the string if it's empty or nil if not empty
-- function utils.string.isEmpty(string) end

-- --- Raycast Camera
-- ---@param distance number --- Distance for the raycast
-- ---@return boolean|integer --- Whether the ray hit an object or not
-- ---@return vector3 --- End position of the raycast
-- ---@return boolean --- Whether the raycast hit water or not
-- ---@return vector3 --- Coordinates of the water hit (if applicable)
-- function utils.raycastCam(distance) end

-- --- Send Notification
-- ---@param msg string --- Message to display
-- ---@param type? string --- Type of notification
-- ---@param duration? number --- Duration of the notification
-- function utils.notify(msg, type, duration) end

-- --- Show & Hide drawtext
-- ---@param type string --- Action to perform ('show' or 'hide')
-- ---@param text? string --- Text to display (if showing)
-- ---@param icon? string --- Icon to display (if showing)
-- function utils.drawtext(type, text, icon) end

-- --- Create context menu
-- ---@param data ContextOptions --- Data for the context menu
-- function utils.createMenu(data) end

-- --- Create a camera for vehicle review
-- ---@param vehicle integer --- Vehicle entity to review
-- function utils.createPreviewCam(vehicle) end

-- --- Destroying the camera to review the vehicle
-- ---@param vehicle integer --- Vehicle entity to review
-- ---@param enterVehicle boolean --- Whether to enter the vehicle after destroying the camera
-- function utils.destroyPreviewCam(vehicle, enterVehicle) end

-- --- Create target ped
-- ---@param model string | integer --- Model for the ped
-- ---@param coords vector4 --- Coordinates for the ped
-- ---@param options TargetOptions[] --- Interaction options for the ped
-- function utils.createTargetPed(model, coords, options) end

-- --- Remove target ped
-- ---@param entity integer --- Entity ID of the ped to remove
-- ---@param label string --- Label of the target to remove
-- function utils.removeTargetPed(entity, label) end

-- --- Get progress color by level (for fuel, engine, body)
-- ---@param level any --- Level to determine color for
-- ---@return string|false? --- Returns the color based on the level, or false if invalid
-- function utils.getColorLevel(level) end

-- --- Get vehicle number plate
-- ---@param vehicle integer --- Vehicle entity
-- ---@return string? --- Returns the vehicle's number plate or nil if not found
-- function utils.getPlate(vehicle) end

-- --- Checking vehicle class
-- ---@param vehType number --- Vehicle class type
-- ---@return string --- Returns the category of the vehicle class
-- function utils.getCategoryByClass(vehType) end

-- --- Set vehicle fuel level
-- ---@param vehicle integer --- Vehicle entity
-- ---@param fuel number --- Fuel level to set
-- function utils.setFuel(vehicle, fuel) end

-- --- Get vehicle fuel level
-- ---@param vehicle integer --- Vehicle entity
-- ---@return number --- Returns the current fuel level of the vehicle
-- function utils.getFuel(vehicle) end

-- --- Create vehicle by client side
-- ---@param model string | integer --- Vehicle model
-- ---@param coords vector4 --- Coordinates for the vehicle
-- ---@param cb? fun(veh: integer) --- Callback function for vehicle creation
-- ---@param network? boolean --- Whether to create the vehicle with network support
-- ---@return integer? --- Returns the vehicle entity ID
-- function utils.createPlyVeh(model, coords, cb, network) end

-- --- Checking or Get garage type
-- ---@param data table[] --- List of garage types
-- ---@return string --- Returns a string describing the garage types
-- function utils.garageType(data) end

-- --- Checking player gang
-- ---@param data table --- Gang-related data
-- ---@return boolean --- Returns whether the player belongs to an allowed gang
-- function utils.GangCheck(data) end

-- --- Checking player job
-- ---@param data table --- Job-related data
-- ---@return boolean --- Returns whether the player has an allowed job
-- function utils.JobCheck(data) end

-- if server then
--     --- Send Notification
--     ---@param src number --- Source of the notification
--     ---@param msg string --- Message to display
--     ---@param type? string --- Type of notification
--     ---@param duration? string --- Duration of the notification
--     function utils.notify(src, msg, type, duration) end
-- end