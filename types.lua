---@class garageZoneBlip
---@field label string     -- The label or name that will appear on the map for this blip.
---@field sprite number    -- The icon or sprite ID used for the blip (e.g., car icon, house icon).
---@field colour number    -- The color ID for the blip, as defined in the game (e.g., blue, red).
---@field coords? vector3   -- The 3D coordinates where the blip will be placed on the map (x, y, z).

---@class garageZonePoints
---@field points vector3[]
---@field thickness number

---@class garagePoints
---@field take vector4
---@field save vector4
---@field useMarker boolean

---@class garageTargetPed
---@field model string
---@field coords vector4

---@class cbData
---@field playerId number
---@field playerName string
---@field playerJob string
---@field playerGang string
---@field playerIdentifier string

---@class garageZone
---@field type string
---@field class string|string[]
---@field label string
---@field zones? garageZonePoints
---@field points? garagePoints
---@field interaction? string|garageTargetPed
---@field spawnPoint? vector4[]
---@field blip? garageZoneBlip
---@field groups? string|string[]|table<string, number>
---@field canAccess? fun(data?:cbData): boolean

--- @class InputData
--- @field engine number
--- @field body number
--- @field fuel number

--- @class MetadataEntry
--- @field label string
--- @field value number
--- @field progress number
--- @field colorScheme string