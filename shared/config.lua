Config = {}

-- Configuration settings
Config.SpawnInVehicle = true --- Set to true if the player should immediately enter the vehicle when taken out of the garage

--- Specifies the fuel script to use:
--- [rhd_fuel](https://rhd.tebex.io/package/6284098) | 
--- [ox_fuel](https://github.com/overextended/ox_fuel/releases) | 
--- [LegacyFuel](https://github.com/InZidiuZ/LegacyFuel.git) | 
--- [ps-fuel](https://github.com/project-sloth/ps-fuel/releases) | 
--- [cdn-fuel](https://github.com/CodineDev/cdn-fuel/releases)
Config.FuelScript = 'rhd_fuel'

--- Specifies the interactions system to use:
--- [ox](https://github.com/overextended/ox_target/releases) |
--- [qb](https://github.com/qbcore-framework/qb-target.git) |
--- [interact](https://github.com/darktrovx/interact)
Config.interact = 'interact'

--- Specifies the radial menu system to use:
--- [ox](https://github.com/overextended/ox_lib/releases) |
--- [qb](https://github.com/qbcore-framework/qb-radialmenu) |
--- [rhd](https://github.com/reyyghi/rhd_radialmenu)
Config.radialMenu = 'ox'

--- If set to true, you will need to use the following resource: 
--- [VehicleDeformation](https://github.com/Kiminaze/VehicleDeformation/releases).
--- This setting enables saving vehicle deformation data, which requires 
--- the VehicleDeformation resource to properly function.
Config.saveDeformation = true

-- Additional settings (Requires ox_target or qb-target resource)
Config.UseJobVechileShop = true --- Set to false if you do not want to use the work vehicle shop system from rhd
Config.UsePoliceImpound = true --- Set to false if you do not want to use the police impound system from rhd

Config.InDevelopment = true --- Set to false when you have finished setting up this garage

Config.ChangeVehicleName = {
    enable = true,
    price = 10
}

-- Vehicle transfer settings
Config.TransferVehicle = {
    enable = true,  --- Enable or disable vehicle transfer functionality
    price = 100     --- Price for transferring a vehicle
}

-- Garage swap settings
Config.SwapGarage = {
    enable = true,  --- Enable or disable garage swapping functionality
    price = 500     --- Price for swapping garages
}